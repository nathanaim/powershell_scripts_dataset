﻿
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Full path to the script that the Consumer will execute")]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
        }
        else {
            
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".ps1") {
                
                if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
                    Write-Warning -Message "Unable to locate part of the specified path" ; break
                }
                elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
                    return $true
                }
                else {
                    Write-Warning -Message "Unhandled error" ; break
                }
            }
            else {
                Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.ps1'" ; break
            }
        }
    })]
    [ValidateNotNullOrEmpty()]
    [string]$ScriptPath
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }
    
    $ScriptFileName = Split-Path -Path $ScriptPath -Leaf
}
Process {
    try {
        
        $InstanceFilterProperties = @{
            QueryLanguage = "WQL"
            Query = "SELECT * FROM __InstanceCreationEvent WITHIN 5 WHERE TargetInstance ISA 'SMS_UserApplicationRequest' AND 'TargetInstance.CurrentState = 1'"
            Name = "ApplicationApprovalFilter"
            EventNameSpace = "root\sms\site_$($SiteCode)"
        }
        $EventFilterInstance = New-CimInstance -Namespace "root\subscription" -ClassName __EventFilter -Property $InstanceFilterProperties -ErrorAction Stop
        
        $ConsumerProperties = @{
            Name = "ApplicationApprovalConsumer";
            CommandLineTemplate = "powershell.exe -File $($ScriptPath)\Change-Ownership.ps1 -SiteServer $SiteServer -SiteCode $SiteCode -DeviceOwner 1 -ResourceId %TargetInstance.ResourceId%"
        }
        $ConsumerInstance = New-CimInstance -Namespace "root\subscription" -ClassName CommandLineEventConsumer -Property $ConsumerProperties -ErrorAction Stop
        
        $BindingProperties = @{
            Filter = [ref]$EventFilterInstance
            Consumer = [ref]$ConsumerInstance
        }
        New-CimInstance -Namespace "root\subscription" -ClassName __FilterToConsumerBinding -Property $BindingProperties -ErrorAction Stop
    }
    catch [System.UnauthorizedAccessException]  {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message
    }
}
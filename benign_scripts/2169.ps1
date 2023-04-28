﻿
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of a Distribution Point Group where all non-distributed packages will be added to")]
    [ValidateNotNullOrEmpty()]
    [string]$DPGroupName
)
Begin {
    
    try {
        Write-Verbose -Message "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug -Message "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
    
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        try {
            Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
            if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }
    
    $CurrentLocation = $PSScriptRoot
    Set-Location -Path $SiteDrive -ErrorAction Stop -Verbose:$false
}
Process {
    
    try {
        $DPGroupID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DPGroupInfo -ComputerName $SiteServer -Filter "Name like '$($DPGroupName)'" -ErrorAction Stop | Select-Object -ExpandProperty GroupID
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine DPGroupID from specified DPGroupName" ; break
        Set-Location -Path $CurrentLocation
    }
    
    try {
        $DPGroupDistributedPackages = New-Object -TypeName System.Collections.ArrayList
        $DPGroupPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DPGroupPackages -ComputerName $SiteServer -Filter "GroupID like '$($DPGroupID)'"
        if ($DPGroupPackages -ne $null) {
            foreach ($DPGroupPackage in $DPGroupPackages) {
                $DPGroupDistributedPackages.Add($DPGroupPackage.PkgID) | Out-Null
            }
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "An error occurred while enumerating packages distributed to specified Distribution Point Group" ; break
        Set-Location -Path $CurrentLocation
    }
    
    try {
        $DriverPackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_DriverPackage -ComputerName $SiteServer -ErrorAction Stop
        if ($DriverPackages -ne $null) {
            foreach ($DriverPackage in $DriverPackages) {
                if ($DriverPackage.PackageID -notin $DPGroupDistributedPackages) {
                    if ($PSCmdlet.ShouldProcess($DriverPackage.Name,"Distribute")) {
                        try {
                            Start-CMContentDistribution -DriverPackageName $DriverPackage.Name -DistributionPointGroupName $DPGroupName -ErrorAction Stop -Verbose:$false | Out-Null
                            Write-Verbose -Message "Successfully distributed '$($DriverPackage.Name)' to Distribution Point Group '$($DPGroupName)'"
                            Write-Verbose -Message "Allowing some time for Distribution Manager to process request"
                            Start-Sleep -Seconds 5
                        }
                        catch [System.Exception] {
                            Write-Warning -Message $_.Exception.Message
                        }
                    }
                }
            }
        }
        else {
            Write-Warning -Message "No package where found on the specified Site Server" ; break
            Set-Location -Path $CurrentLocation
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        Set-Location -Path $CurrentLocation
    }
}
End {
    Set-Location -Path $CurrentLocation
}
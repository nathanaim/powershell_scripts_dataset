﻿
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="Recurse", HelpMessage="Site server where the SMS Provider is installed")]
    [parameter(Mandatory=$true, ParameterSetName="CSV")]
    [parameter(Mandatory=$true, ParameterSetName="Static")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, ParameterSetName="CSV", HelpMessage="Path to a CSV file containing the CollectionName and CollectionID")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(csv)$")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	    }
	    else {
		    
		    if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
			    Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
		    }
		    elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
			    return $true
		    }
		    else {
			    Write-Warning -Message "Unhandled error" ; break
		    }
	    }
    })]
    [string]$Path,
    [parameter(Mandatory=$false, ParameterSetName="CSV", HelpMessage="Specify the delimiter used in the CSV file")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet(",",";")]
    [string]$Delimiter = ",",
    [parameter(Mandatory=$true, ParameterSetName="Static", HelpMessage="Name of a collection that will have Incremental Updates disabled")]
    [ValidateNotNullOrEmpty()]
    [string]$CollectionName,
    [parameter(Mandatory=$false, ParameterSetName="Recurse", HelpMessage="Show a progressbar displaying the current operation")]
    [parameter(Mandatory=$false, ParameterSetName="CSV")]
    [parameter(Mandatory=$false, ParameterSetName="Static")]
    [switch]$ShowProgress
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
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }
    
    function Disable-IncrementalCollectionSetting {
        param(
            [parameter(Mandatory=$true)]
            $Collection
        )
        $ErrorActionPreference = "Stop"
        try {
            if ((($Collection.RefreshType -eq 6) -or ($Collection.RefreshType -eq 4)) -and ($Collection.CollectionID -notlike "SMS*")) {
                Write-Verbose -Message "Attempting to disable Incremental Updates for device collection: $($Collection.Name)"
                if ($PSCmdlet.ShouldProcess($Collection.Name,"Disable Incremental Updates")) {
                    $Collection.Get()
                    $Collection.RefreshType = 2
                    $Collection.Put() | Out-Null
                }
                Write-Verbose -Message "Successfully disabled Incremental Updates for device collection: $($Collection.Name)"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message "An error occured when attempting to update collection setting for collection: $($Collection.Name)" ; return
        }
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        "CSV" {
            $Collections = Import-Csv -Path $Path -Delimiter $Delimiter
            if ($Collections -ne $null) {
                foreach ($Collection in $Collections) {
                    try {
                        $CollectionObject = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "CollectionID like '$($Collection.CollectionID)'" -ErrorAction Stop
                        if ($CollectionObject -ne $null) {
                            Disable-IncrementalCollectionSetting -Collection $CollectionObject
                        }
                        else {
                            Write-Warning -Message "Unable to find collection: $($Collection.CollectionID)"
                        }
                    }
                    catch [System.Exception] {
                        Write-Warning -Message $_.Exception.Message ; return
                    }
                }
            }
        }
        "Recurse" {
            try {
                $Collections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -ErrorAction Stop
                if ($Collections -ne $null) {
                    foreach ($Collection in $Collections) {
                        Disable-IncrementalCollectionSetting -Collection $Collection
                    }
                }
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }
        "Static" {
            try {
                $Collection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($CollectionName)'" -ErrorAction Stop
                if ($Collection -ne $null) {
                    Disable-IncrementalCollectionSetting -Collection $Collection
                }
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }
        }
    }
}
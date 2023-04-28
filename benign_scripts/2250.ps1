
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Set the URI for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$URI,

    [parameter(Mandatory=$true, HelpMessage="Specify the known secret key for the ConfigMgr WebService.")]
    [ValidateNotNullOrEmpty()]
    [string]$SecretKey,

    [parameter(Mandatory=$false, HelpMessage="Define a filter used when calling ConfigMgr WebService to only return objects matching the filter.")]
    [ValidateNotNullOrEmpty()]
    [string]$Filter = [System.String]::Empty
)
Begin {
    
    try {
        $TSEnvironment = New-Object -ComObject Microsoft.SMS.TSEnvironment -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to construct Microsoft.SMS.TSEnvironment object" ; exit 1
    }
}
Process {
    
    function Write-CMLogEntry {
	    param(
		    [parameter(Mandatory=$true, HelpMessage="Value added to the log file.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$Value,

		    [parameter(Mandatory=$true, HelpMessage="Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.")]
		    [ValidateNotNullOrEmpty()]
            [ValidateSet("1", "2", "3")]
		    [string]$Severity,

		    [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
		    [ValidateNotNullOrEmpty()]
		    [string]$FileName = "BIOSPackageDownload.log"
	    )
	    
        $LogFilePath = Join-Path -Path $Script:TSEnvironment.Value("_SMSTSLogPath") -ChildPath $FileName

        
        $Time = -join @((Get-Date -Format "HH:mm:ss.fff"), "+", (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))

        
        $Date = (Get-Date -Format "MM-dd-yyyy")

        
        $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

        
        $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""BIOSPackageDownloader"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
	
	    
        try {
	        Add-Content -Value $LogText -LiteralPath $LogFilePath -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "Unable to append log entry to BIOSPackageDownload.log file. Error message: $($_.Exception.Message)"
        }
    }

    function Compare-BIOSVersion {
		param (
			[parameter(Mandatory = $true, HelpMessage = "Current available BIOS version.")]
			[ValidateNotNullOrEmpty()]
			[string]$AvailableBIOSVersion
		)
		
		
		$CurrentBIOSVersion = (Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion).Trim()
		
		
		if ($CurrentBIOSVersion -like "*.*.*") {
			
			if ([System.Version]$AvailableBIOSVersion -gt [System.Version]$CurrentBIOSVersion) {
				
				$TSEnvironment.Value("NewBIOSAvailable") = $true
				Write-CMLogEntry -Value "A new version of the BIOS has been detected. Current release $($CurrentBIOSVersion) will be replaced by $($AvailableBIOSVersion)." -Severity 1
			}
		}
		elseif ($CurrentBIOSVersion -like "A*") {
			
			if ($AvailableBIOSVersion -like "*.*.*") {
				
				
				$TSEnvironment.Value("NewBIOSAvailable") = $true
				Write-CMLogEntry -Value "A new version of the BIOS has been detected. Current release $CurrentBIOSVersion will be replaced by $AvailableBIOSVersion." -Severity 1
			}
			elseif ($AvailableBIOSVersion -gt $CurrentBIOSVersion) {
				
				$TSEnvironment.Value("NewBIOSAvailable") = $true
				Write-CMLogEntry -Value "A new version of the BIOS has been detected. Current release $CurrentBIOSVersion will be replaced by $AvailableBIOSVersion." -Severity 1
			}
		}
	}

    
    Write-CMLogEntry -Value "BIOS download package process initiated" -Severity 1

    
    $ComputerManufacturer = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer).Trim()
    Write-CMLogEntry -Value "Manufacturer determined as: $($ComputerManufacturer)" -Severity 1

    
    switch -Wildcard ($ComputerManufacturer) {
        "*Dell*" {
            $ComputerManufacturer = "Dell"
            $ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model).Trim()
        }
        "*Lenovo*" {
            $ComputerManufacturer = "Lenovo"
            $ComputerModel = Get-WmiObject -Class Win32_ComputerSystemProduct | Select-Object -ExpandProperty Version
        }
    }
    Write-CMLogEntry -Value "Computer model determined as: $($ComputerModel)" -Severity 1
	
	
	$CurrentBIOSVersion = (Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SMBIOSBIOSVersion).Trim()
	Write-CMLogEntry -Value "Current BIOS version determined as: $($CurrentBIOSVersion)" -Severity 1
	
    
    try {
        $WebService = New-WebServiceProxy -Uri $URI -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "Unable to establish a connection to ConfigMgr WebService. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    
    try {
        $Packages = $WebService.GetCMPackage($SecretKey, "$($Filter)")
        Write-CMLogEntry -Value "Retrieved a total of $(($Packages | Measure-Object).Count) BIOS packages from web service" -Severity 1
    }
    catch [System.Exception] {
        Write-CMLogEntry -Value "An error occured while calling ConfigMgr WebService for a list of available packages. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
    }

    
    $PackageList = New-Object -TypeName System.Collections.ArrayList

    
    $ErrorActionPreference = "Stop"

     
    if ($ComputerManufacturer -eq "Dell" -or $ComputerManufacturer -eq "Lenovo") {
        
        if ($Packages -ne $null) {
            
            foreach ($Package in $Packages) {
                
                if (($Package.PackageName -match $ComputerModel) -and ($ComputerManufacturer -match $Package.PackageManufacturer)) {                            
                    Write-CMLogEntry -Value "Match found for computer model and manufacturer: $($Package.PackageName) ($($Package.PackageID))" -Severity 1
                    $PackageList.Add($Package) | Out-Null
                }
				elseif (($Package.PackageName -match $(($ComputerModel).Split(' ') | Select-Object -Last 1)) -and ($ComputerManufacturer -eq "Lenovo")){
                    Write-CMLogEntry -Value "Match found for computer model and manufacturer: $($Package.PackageName) ($($Package.PackageID))" -Severity 1
                    $PackageList.Add($Package) | Out-Null	
				}					
                else {
                    Write-CMLogEntry -Value "Package does not meet computer model and manufacturer criteria: $($Package.PackageName) ($($Package.PackageID))" -Severity 2
                }
            }

            
            if ($PackageList -ne $null) {
                
                if ($PackageList.Count -eq 1) {
                    Write-CMLogEntry -Value "BIOS package list contains a single match, attempting to set task sequence variable" -Severity 1

                    
                    Compare-BIOSVersion -AvailableBIOSVersion $PackageList[0].PackageVersion

                    if ($TSEnvironment.Value("NewBIOSAvailable") -eq $true) {
                        
                        try {
                            $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($PackageList[0].PackageID)
                            Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($PackageList[0].PackageID)" -Severity 1
                        }
                        catch [System.Exception] {
                            Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                        }
                    }
                    else {
                        Write-CMLogEntry -Value "BIOS is already up to date with the latest $($PackageList[0].PackageVersion) version" -Severity 1
                    }
                }
                elseif ($PackageList.Count -ge 2) {
                    Write-CMLogEntry -Value "BIOS package list contains multiple matches, attempting to set task sequence variable" -Severity 1

                    
                    $Package = $PackageList | Sort-Object -Property PackageCreated -Descending | Select-Object -First 1

                    
                    Compare-BIOSVersion -AvailableBIOSVersion $Package.PackageVersion

                    if ($TSEnvironment.Value("NewBIOSAvailable") -eq $true) {
                        
                        try {
                            $TSEnvironment.Value("OSDDownloadDownloadPackages") = $($Package.PackageID)
                            Write-CMLogEntry -Value "Successfully set OSDDownloadDownloadPackages variable with PackageID: $($Package.PackageID)" -Severity 1
                        }
                        catch [System.Exception] {
                            Write-CMLogEntry -Value "An error occured while setting OSDDownloadDownloadPackages variable. Error message: $($_.Exception.Message)" -Severity 3 ; exit 1
                        }                        
                    }
                    else {
                        Write-CMLogEntry -Value "BIOS is already up to date with the latest $($Package.PackageVersion) version" -Severity 1
                    }
                }
                else {
                    Write-CMLogEntry -Value "Unable to determine a matching BIOS package from list since an unsupported count was returned from package list, bailing out" -Severity 2 ; exit 1
                }
            }
			else {
                Write-CMLogEntry -Value "Empty BIOS package list detected, bailing out" -Severity 1
            }
        }
        else {
            Write-CMLogEntry -Value "BIOS package list returned from web service did not contain any objects matching the computer model and manufacturer, bailing out" -Severity 1
        }
    }
    else {
        Write-CMLogEntry -Value "This script is supported on Dell and Lenovo systems only at this point, bailing out" -Severity 1
    }
}
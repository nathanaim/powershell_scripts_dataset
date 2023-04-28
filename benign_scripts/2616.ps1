﻿function New-MSFLabImage{
[CmdletBinding()]
param([string]$ISO
     ,[string]$OutputPath
     ,[string]$ImageName
     ,[string]$Edition
     ,[string]$UnattendXML
     ,[string[]]$CustomModules
)
$ErrorActionPreference = 'Stop'


. C:\git-repositories\PowerShell\Convert-WindowsImage.ps1


Write-Verbose "Validating Build Paths..."
if(!(Test-Path $ISO)){Write-Error "ISO Path invalid: $ISO"}
if(!(Test-Path $OutputPath)){Write-Error "ISO Path invalid: $OutputPath"}


$OutputFile = Join-Path -Path $OutputPath -ChildPath $ImageName


if(Test-Path $OutputFile){Remove-Item $OutputFile}
if($UnattendXML.Length -gt 0){
        Write-Verbose "Creating image $ImageName using $UnattendXML"
        Convert-WindowsImage -SourcePath $ISO -VHDPath $OutputFile -VHDFormat VHDX -VHDType Dynamic -Edition $Edition -VHDPartitionStyle MBR -UnattendPath $UnattendXML
    }
    else{
        Write-Verbose "Creating image $ImageName"
        Convert-WindowsImage -SourcePath $ISO -VHDPath $OutputFile -VHDFormat VHDX -VHDType Dynamic -Edition $Edition -VHDPartitionStyle MBR
    }

if($CustomModules -and (Test-Path $OutputFile)){
    Write-Verbose "Mounting $ImageName to load custome Powershell modules"
    $DriveLetter = (Mount-VHD $OutputFile –PassThru | Get-Disk | Get-Partition | Get-Volume).DriveLetter
    foreach($Module in $CustomModules){
        if(Test-Path $Module){  
        Write-Verbose "Adding $Module"  
        Copy-Item -Path $module -Destination "$DriveLetter`:\Program Files\WindowsPowershell\Modules" -Recurse
            }
        }
    Write-Verbose "Dismounting $ImageName"
    Dismount-VHD -Path $OutputFile
    }
}

$custom = @('C:\git-repositories\PowerShell\SqlConfiguration')
New-MSFLabImage -ISO 'C:\VMS\ISOs\en_windows_server_2016_x64_dvd_9718492.ISO' -OutputPath 'C:\VMS\ISOs' -ImageName 'GM2016Core.vhdx' -Edition ServerStandardCore -CustomModules $custom -Verbose -UnattendXML C:\vms\ISOs\SERVER2016.xml
New-MSFLabImage -ISO 'C:\VMS\ISOs\en_windows_server_2016_x64_dvd_9718492.ISO' -OutputPath 'C:\VMS\ISOs' -ImageName 'GM2016Full.vhdx' -Edition ServerStandard -CustomModules $custom -Verbose -UnattendXML C:\vms\ISOs\SERVER2016.xml

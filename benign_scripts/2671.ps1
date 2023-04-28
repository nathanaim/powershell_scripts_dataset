﻿Function Install-SharePointPnPPowerShellModule {



param (
        [Parameter(Mandatory=$true,HelpMessage='Online is for SharePoint Online, SP2013 for SharePoint 2013 and SP2016 for SharePoint 2016')]
        [ValidateSet('Online','SP2013','SP2016')]
        [string] $ModuleToInstall   
       )
       

       switch ($ModuleToInstall)
       {
            'Online' { 
                $moduleVersion = 'SharePoint Online'
                $moduleName = 'SharePointPnPPowerShellOnline'
                }
            'SP2013' {
                $moduleVersion = 'SharePoint 2013'
                $moduleName = 'SharePointPnPPowerShell2013'
            }
            'SP2016' {
                $moduleVersion = 'SharePoint 2016'
                $moduleName = 'SharePointPnPPowerShell2016'
            }
       }

       if (!(Get-command -Module $moduleName).count -gt 0)
       {
           Install-Module -Name $moduleName -Force -SkipPublisherCheck
       }

       Write-Output -InputObject "The modules for $moduleVersion have been installed and can now be used"
       Write-Output -InputObject 'On the next release you can just run Update-Module -force to update this and other installed modules'
}

function Request-SPOOrOnPremises
{
    [string]$title="Confirm"
    [string]$message="Which version of the Modules do you want to install?"
    
	$SPO = New-Object -TypeName System.Management.Automation.Host.ChoiceDescription -ArgumentList "SharePoint &Online", "SharePoint Online"
    $SP2016 = New-Object -TypeName System.Management.Automation.Host.ChoiceDescription -ArgumentList "SharePoint 201&6", "SharePoint 2016"
	$SP2013 = New-Object -TypeName System.Management.Automation.Host.ChoiceDescription -ArgumentList "SharePoint 201&3", "SharePoint 2013"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($SPO, $SP2016, $SP2013)

	$result = $host.ui.PromptForChoice($title, $message, $options, 0)

	switch ($result)
	{
        2 { Return 'SP2013'}
		1 { Return 'SP2016' } 
		0 { Return 'Online' }
	}
}


if ((Get-command -Module PowerShellGet).count -gt 0) 
    { 
    Write-Output -InputObject 'PowerShellPackageManagement now installed we will now run the next command in 10 Seconds'
    Start-Sleep -Seconds 10 
    Install-SharePointPnPPowerShellModule -ModuleToInstall (Request-SPOOrOnPremises)
    }
    else
        {
        Write-Output -InputObject "PowerShellPackageManagement is not installed on this Machine - Please run the below to install - you will need to Copy and Paste it as i'm not doing everything for you ;-)"
        Write-Output -InputObject "Invoke-Expression (New-Object -TypeName Net.WebClient).DownloadString('http://bit.ly/PSPackManInstall')"
        }

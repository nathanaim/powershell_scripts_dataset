function ShowMenu {
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Title,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ChoiceMessage,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$NoMessage = 'No thanks'
	)

	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $ChoiceMessage
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoMessage
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	PromptChoice -Title $Title -ChoiceMessage $ChoiceMessage -options $options
}

function PromptChoice {
	param(
		$Title,
		$ChoiceMessage,
		$Options
	)
	$host.ui.PromptForChoice($Title, $ChoiceMessage, $options, 0)
}

function GetRequiredManifestKeyParams {
	
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string[]]$RequiredKeys = @('Description', 'Version', 'ProjectUri', 'Author')
	)
	
	$paramNameMap = @{
		Version     = 'ModuleVersion'
		Description = 'Description'
		Author      = 'Author'
		ProjectUri  = 'ProjectUri'
	}
	$params = @{ }
	foreach ($val in $RequiredKeys) {
		$result = Read-Host -Prompt "Input value for module manifest key: [$val]"
		$paramName = $paramNameMap.$val
		$params.$paramName = $result
	}
	$params
}

function Invoke-Test {
	param(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$TestName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Test', 'Fix')]
		[string]$Action,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[object]$Module
	)
	
	$testHt = $moduleTests | where { $_.TestName -eq $TestName }
	$actionName = '{0}{1}' -f $Action, 'Action'
	& $testHt.$actionName -Module $Module
}

function Publish-PowerShellGalleryModule {
	

	[CmdletBinding(DefaultParameterSetName = 'ByName')]
	param(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({
				if (-not (Test-Path -Path $_ -PathType Leaf)) {
					throw "The module $($_) could not be found."
				} else {
					$true
				}
			})]
		[string]$ModuleFilePath,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$RunOptionalTests,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$NuGetApiKey,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$PublishToGallery
	)

	
	$moduleTests = @(
		@{
			TestName       = 'Module manifest exists'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not exist at the expected path.'
			FixMessage     = 'Run New-ModuleManifest to create a new manifest'
			FixAction      = { 
				param($Module)

				
				$newManParams = @{ Path = $Module.Path }
				$newManParams += GetRequiredManifestKeyParams

				
				Write-Verbose -Message "Running New-ModuleManifest with params: [$($newManParams | Out-String)]"
				New-ModuleManifest @newManParams
			}
			TestAction     = {
				param($Module)

				
				if (-not (Test-Path -Path $Module.Path -PathType Leaf)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Manifest has all required keys'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not have all the required keys populated.'
			FixMessage     = 'Run Update-ModuleManifest to update existing manifest'
			FixAction      = { 
				param($Module)

				
				$Module = Get-Module -Name $Module.Path -ListAvailable

				
				$updateManParams = @{ Path = $Module.Path }
				$missingKeys = ($Module.PsObject.Properties | Where-Object -FilterScript { $_.Name -in @('Description', 'Author', 'Version') -and (-not $_.Value) }).Name
				if ((-not $Module.LicenseUri) -and (-not $Module.PrivateData.PSData.ProjectUri)) {
					$missingKeys += 'ProjectUri'
				}

				$updateManParams += GetRequiredManifestKeyParams -RequiredKeys $missingKeys
				Update-ModuleManifest @updateManParams
			}
			TestAction     = {
				param($Module)

				
				
				$Module = Get-Module -Name $Module.Path -ListAvailable
					
				if ($Module.PsObject.Properties | Where-Object -FilterScript { $_.Name -in @('Description', 'Author', 'Version') -and (-not $_.Value) }) {
					$false
				} elseif ((-not $Module.LicenseUri) -and (-not $Module.PrivateData.PSData.ProjectUri)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Manifest passes Test-Modulemanifest validation'
			Mandatory      = $true
			FailureMessage = 'The module manifest does not pass validation with Test-ModuleManifest'
			FixMessage     = 'Run Test-ModuleManifest explicitly to investigate problems discovered'
			FixAction      = {
				param($Module)
				Test-ModuleManifest -Path $module.Path
			}
			TestAction     = {
				param($Module)
				if (-not (Test-ModuleManifest -Path $Module.Path -ErrorAction SilentlyContinue)) {
					$false
				} else {
					$true
				}
			}
		}
		@{
			TestName       = 'Pester Tests Exists'
			Mandatory      = $false
			FailureMessage = 'The module does not have any associated Pester tests.'
			FixMessage     = 'Create a new Pester test file using a common template'
			FixAction      = { 
				param($Module)

				
				
				$pesterTestPath = "$($Module.ModuleBase)\$($Module.Name).Tests.ps1"
				$publicFunctionNames = (Get-Command -Module $Module).Name

				$templateFuncs = ''
				$templateFuncs += $publicFunctionNames | foreach {
					@"
		describe '$_' {
			
		}

"@
				}

				
				
				$pesterTestTemplate = @'

$ThisModule = "$($MyInvocation.MyCommand.Path -replace "\.Tests\.ps1$", '').psm1"
$ThisModuleName = (($ThisModule | Split-Path -Leaf) -replace ".psm1")
Get-Module -Name $ThisModuleName -All | Remove-Module -Force

Import-Module -Name $ThisModule -Force -ErrorAction Stop



@(Get-Module -Name $ThisModuleName).where({{ $_.version -ne "0.0" }}) | Remove-Module -Force


InModuleScope $ThisModuleName {{
{0}
}}
'@ -f $templateFuncs

				Add-Content -Path $pesterTestPath -Value $pesterTestTemplate
			}
			TestAction     = {
				param($Module)

				if (-not (Test-Path -Path "$($Module.ModuleBase)\$($Module.Name).Tests.ps1" -PathType Leaf)) {
					$false
				} else {
					$true
				}
			}
		}
	)

	try {

		if (-not $NuGetApiKey) {
			throw @"
The NuGet API key was not found in the NuGetAPIKey parameter. In order to publish to the PowerShell Gallery this key is required. 
Go to https://www.powershellgallery.com/users/account/LogOn?returnUrl=%2F for instructions on registering an account and obtaining 
a NuGet API key.
"@
		}

		$module = Get-Module -Name $ModuleFilePath -ListAvailable

		
		$module | Add-Member -MemberType NoteProperty -Name 'Path' -Value "$($module.ModuleBase)\$($Module.Name).psd1" -Force
		
		if ($RunOptionalTests.IsPresent) {
			$whereFilter = { '*' }
		} else {
			$whereFilter = { $_.Mandatory }
		}

		foreach ($test in ($moduleTests | where $whereFilter)) {
			if (-not (Invoke-Test -TestName $test.TestName -Action 'Test' -Module $module)) {			
				$result = ShowMenu -Title $test.FailureMessage -ChoiceMessage "Would you like to resolve this with action: [$($test.FixMessage)]?"
				switch ($result) {
					0 {
						Write-Verbose -Message 'Running fix action...'
						Invoke-Test -TestName $test.TestName -Action 'Fix' -Module $module
					}
					1 { Write-Verbose -Message 'Leaving the problem be...' }
				}
			} else {
				Write-Verbose -Message "Module passed test: [$($test.TestName)]"
			}
		}

		$publishAction = {
			Write-Verbose -Message 'Publishing module...'
			Publish-Module -Name $module.Name -NuGetApiKey $NuGetApiKey
			Write-Verbose -Message 'Done.'
		}
		if ($PublishToGallery.IsPresent) {
			& $publishAction
		} else {
			$result = ShowMenu -Title 'PowerShell Gallery Publication' -ChoiceMessage 'All mandatory tests have passed. Publish it?'
			switch ($result) {
				0 {
					& $publishAction
				}
				1 { 
					Write-Host "Postponing publishing. When ready, use this syntax: Publish-Module -Name $($module.Name) -NuGetApiKey $NuGetApiKey"
				}
			}
		}

	} catch {
		Write-Error -Message $_.Exception.Message
	}
}
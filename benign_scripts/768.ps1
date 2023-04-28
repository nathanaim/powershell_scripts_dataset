param([string]$EditorServicesRepoPath = "")

$ErrorActionPreference = "Stop"


if (!(Test-Path "package.json"))
{
	throw "This script must be run from the root vscode-powershell folder (contains package.json)."	
}

if ([string]::IsNullOrEmpty($EditorServicesRepoPath) -or !(Test-Path $EditorServicesRepoPath))
{
	throw "Must provide path to a PowerShell Editor Services Git repository"
}

$hostBinPath = Join-Path $EditorServicesRepoPath "src\PowerShellEditorServices.Host\bin\Debug"

if (!(Test-Path $hostBinPath))
{
	throw "The path '$hostBinPath' was not found.  Has the Editor Services solution been compiled?"
}

Remove-Item -Path ".\bin\*"
Copy-Item -Path "$hostBinPath\*" -Include ("*.exe", "*.dll", "*.pdb", "*.xml") -Exclude ("*.vshost.exe") -Destination ".\bin"

$packageFiles = @(
	"out",
	"bin",
	
	"package.json",
	
	"Third Party Notices.txt",
	"snippets",
	"examples"
)


Compress-Archive -DestinationPath "vscode-powershell.zip" -Path $packageFiles -Force


Compress-Archive -DestinationPath "vscps-preview.zip" -Path @(".\build\InstallPreview.ps1", "vscode-powershell.zip") -Force

Write-Output "Packaging complete."

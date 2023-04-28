

[cmdletbinding()]
param (
    $Task = 'Default',

    [ValidateSet('Build','Minor','Major')]
    $StepVersionBy = 'Build'
)


Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

$Modules = @("Psake", "PSDeploy","BuildHelpers","PSScriptAnalyzer", "Pester")

ForEach ($Module in $Modules) {
    If (-not (Get-Module -Name $Module -ListAvailable)) {
        Switch ($Module) {
            Pester  {Install-Module $Module -Force -SkipPublisherCheck}
            Default {Install-Module $Module -Force}
        }
    }
    Import-Module $Module
}

$Path = (Resolve-Path $PSScriptRoot\..).Path
Set-BuildEnvironment -Path $Path -Force

$invokepsakeSplat = @{
    buildFile  = "$PSScriptRoot\psake.ps1"
    taskList   = $Task
    properties = @{'StepVersionBy' = $StepVersionBy}
    nologo     = $true
}
Invoke-psake @invokepsakeSplat

exit ([int](-not $psake.build_success))

﻿

Properties {
    
        $ProjectRoot = $ENV:BHProjectPath
        if(-not $ProjectRoot)
        {
            $ProjectRoot = Split-Path $PSScriptRoot -Parent
        }

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if($ENV:BHCommitMessage -match "!verbose")
    {
        $Verbose = @{Verbose = $True}
    }
}

Task Default -Depends Deploy

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Test -Depends Init  {
    $lines
    "`nTests?  Maybe some day."

    "`n"
}

Task Build -Depends Test {
    $lines
    
    
    $ModuleName = 'WFTools'
    $Guid = 'afb48b37-44c5-456d-ab0e-05cce6366994'
    $ModPath = Join-Path $ProjectRoot $ModuleName
    $PSD1Path = Join-Path $ModPath WFTools.psd1
    $Null = mkdir WFTools
    Copy-Item $ProjectRoot\*.ps1 $ModPath
    Copy-Item $ProjectRoot\.build\WFTools.psm1 $ModPath
    New-ModuleManifest -Guid $Guid `
                       -Path $PSD1Path `
                       -Author 'Warren Frame' `
                       -ProjectUri https://github.com/RamblingCookieMonster/PowerShell `
                       -LicenseUri https://github.com/RamblingCookieMonster/PowerShell/blob/master/LICENSE `
                       -RootModule 'WFTools.psm1' `
                       -ModuleVersion "0.1.$env:BHBuildNumber" `
                       -Description "Assorted handy, largely unrelated PowerShell functions" `
                       -FunctionsToExport '*' `
                       -Tags 'AD', 'Active', 'Directory',
                             'Azure', 'SQL', 'GPP', 'Smorgasbord'

    $PSD1 = Get-Content $PSD1Path -Raw
    $PSD1 = $PSD1 -replace 'RootModule', 'ModuleToProcess'

    
    Set-BuildEnvironment -Force

    
    Set-ModuleFunctions

    if(-not $ENV:BHPSModulePath)
    {
        Get-Item ENV:BH*
        Throw 'BuildHelpers fail!'
    }
}

Task Deploy -Depends Build {
    $lines

    $Params = @{
        Path = $ProjectRoot
        Force = $true
    }
    Invoke-PSDeploy @Verbose @Params
}

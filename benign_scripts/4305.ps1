﻿





if($IsLinux) {
    return
}

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesScriptsPath = Get-AllUsersScriptsPath
    $script:MyDocumentsScriptsPath = Get-CurrentUserScriptsPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $script:CurrentPSGetFormatVersion = "1.0"
    $script:OutdatedNuGetExeVersion = [System.Version]"2.8.60717.93"

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:PSGalleryRepoPath = Join-Path -Path $script:TempPath -ChildPath 'PSGallery Repo With Spaces'
    RemoveItem $script:PSGalleryRepoPath
    $null = New-Item -Path $script:PSGalleryRepoPath -ItemType Directory -Force

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    Set-PSGallerySourceLocation -Location $script:PSGalleryRepoPath `
                                -PublishLocation $script:PSGalleryRepoPath `
                                -ScriptSourceLocation $script:PSGalleryRepoPath `
                                -ScriptPublishLocation $script:PSGalleryRepoPath

    $modSource = Get-PSRepository -Name "PSGallery"
    AssertEquals $modSource.SourceLocation $script:PSGalleryRepoPath "Test repository's SourceLocation is not set properly"
    AssertEquals $modSource.PublishLocation $script:PSGalleryRepoPath "Test repository's PublishLocation is not set properly"

    $script:ApiKey="TestPSGalleryApiKey"

    
    $script:TempScriptsPath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempScriptsPath -ItemType Directory -Force

    $script:TempScriptsLiteralPath = Join-Path -Path $script:TempScriptsPath -ChildPath 'Lite[ral]Path'
    $null = New-Item -Path $script:TempScriptsLiteralPath -ItemType Directory -Force

    $script:PublishScriptName = 'Fabrikam-TestScript'
    $script:PublishScriptVersion = '1.0.0'
    $script:PublishScriptFilePath = Join-Path -Path $script:TempScriptsPath -ChildPath "$script:PublishScriptName.ps1"
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        RemoveItem $script:moduleSourcesFilePath
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force

    RemoveItem $script:PSGalleryRepoPath
    RemoveItem $script:TempScriptsPath
}

Describe PowerShell.PSGet.PublishNonEnglishCharacterScriptTests -Tags 'BVT' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {

    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem $script:PublishScriptFilePath
        RemoveItem "$script:TempScriptsPath\*.ps1"
        RemoveItem "$script:TempScriptsLiteralPath\*"

    }

    It "PublishScriptRoundTripsNonAnsiCharacters" {
        $description = "Remplace toutes les occurrences d'un modèle de caractère"
        New-ScriptFileInfo -Path $script:PublishScriptFilePath `
            -Version $script:PublishScriptVersion `
            -Author Author@contoso.com `
            -Description $description `
            -Force

        $sfi = Test-ScriptFileInfo -Path $script:PublishScriptFilePath
        AssertEquals $description $sfi.Description

        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName

        AssertEquals $description $psgetItemInfo.description
    }

}
Describe PowerShell.PSGet.PublishScriptTests -Tags 'BVT','InnerLoop' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {

        $null = New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                               -Version $script:PublishScriptVersion `
                               -Author Author@contoso.com `
                               -Description 'Test script description goes here ' `
                               -Force

        Add-Content -Path $script:PublishScriptFilePath `
                    -Value "
                        Function Test-ScriptFunction { 'Test-ScriptFunction' }

                        Workflow Test-ScriptWorkflow { 'Test-ScriptWorkflow' }

                        Test-ScriptFunction
                        Test-ScriptWorkflow"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem $script:PublishScriptFilePath
        RemoveItem "$script:TempScriptsPath\*.ps1"
        RemoveItem "$script:TempScriptsLiteralPath\*"

    }




    
    
    
    
    
    
    
    
    It PublishScriptWithVersionedRequiredScriptDependencies {
        $repoName = "PSGallery"
        $ScriptName = "Script-WithDependencies1"

        
        $RequiredScriptNames = @(
                                'Required-ScriptRequiredVersion',
                                'Required-ScriptMinAndMaxVersion',
                                'Required-ScriptMaxVersion',
                                'Required-ScriptMinVersion'
                             )

        $Versions = @('1.0.0', '1.4.0', '2.0.0', '2.5.0')
        foreach($requiredScriptName in $RequiredScriptNames)
        {
            foreach($dependencyVersion in $Versions) {
                CreateAndPublish-TestScript -Name $requiredScriptName `
                                            -Version $dependencyVersion `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName
            }
        }

        $RequiredScripts = @(
                            "$($RequiredScriptNames[0]):[$($Versions[0])]",
                            "$($RequiredScriptNames[1]):[$($Versions[0]),$($Versions[2])]",
                            "$($RequiredScriptNames[2]):(,$($Versions[1])]",
                            "$($RequiredScriptNames[3]):$($Versions[3])"
                            )
        for($index = 0 ; $index -lt $RequiredScripts.Count ; $index++)
        {
            CreateAndPublish-TestScript -Name $ScriptName `
                                        -Version $Versions[$index] `
                                        -NuGetApiKey $ApiKey `
                                        -Repository $repoName `
                                        -RequiredScripts $RequiredScripts[$index]
        }

        $res1 = Find-Script -Name $ScriptName -RequiredVersion $Versions[0]
        AssertEqualsCaseInsensitive $res1.Name "$ScriptName" "Find-Script didn't find the exact script which has dependencies, $($res1 | Out-String)"
        AssertEquals $res1.Dependencies.Count 1 "Find-Script with -IncludeDependencies returned wrong results, $($res1 | Out-String)"
        AssertEqualsCaseInsensitive $res1.Dependencies.Name $RequiredScriptNames[0] "Find-Script didn't find the exact script which has dependencies, $($res1.Dependencies | Out-String)"
        AssertEquals $res1.Dependencies.RequiredVersion $Versions[0] "Find-Script returned incorrect required version, $($res1.Dependencies | Out-String)"

        $res2 = Find-Script -Name $ScriptName -RequiredVersion $Versions[1]
        AssertEqualsCaseInsensitive $res2.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $($res2 | Out-String)"
        AssertEquals $res2.Dependencies.Count 1 "Find-Script with -IncludeDependencies returned wrong results, $($res2 | Out-String)"
        AssertEqualsCaseInsensitive $res2.Dependencies.Name $RequiredScriptNames[1] "Find-Script didn't find the exact script which has dependencies, $($res2.Dependencies | Out-String)"
        AssertEquals $res2.Dependencies.MinimumVersion $Versions[0] "Find-Script returned incorrect minimum version, $($res2.Dependencies | Out-String)"
        AssertEquals $res2.Dependencies.MaximumVersion $Versions[2] "Find-Script returned incorrect maximum version, $($res2.Dependencies | Out-String)"
        AssertNullOrEmpty $res2.Dependencies.RequiredVersion "Required version should not exist, $($res2.Dependencies | Out-String)"

        $res3 = Find-Script -Name $ScriptName -RequiredVersion $Versions[2]
        AssertEqualsCaseInsensitive $res3.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $($res3 | Out-String)"
        AssertEquals $res3.Dependencies.Count 1 "Find-Script with -IncludeDependencies returned wrong results, $($res3 | Out-String)"
        AssertEqualsCaseInsensitive $res3.Dependencies.Name $RequiredScriptNames[2] "Find-Script didn't find the exact script which has dependencies, $($res3.Dependencies | Out-String)"
        AssertEquals $res3.Dependencies.MaximumVersion $Versions[1] "Find-Script returned incorrect maximum version, $($res3.Dependencies | Out-String)"
        AssertNullOrEmpty $res3.Dependencies.MinimumVersion "Minimum version should not exist, $($res3.Dependencies | Out-String)"
        AssertNullOrEmpty $res3.Dependencies.RequiredVersion "Required version should not exist, $($res3.Dependencies | Out-String)"

        $res4 = Find-Script -Name $ScriptName -RequiredVersion $Versions[3]
        AssertEqualsCaseInsensitive $res4.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $($res4 | Out-String)"
        AssertEquals $res4.Dependencies.Count 1 "Find-Script with -IncludeDependencies returned wrong results, $($res4 | Out-String)"
        AssertEqualsCaseInsensitive $res4.Dependencies.Name $RequiredScriptNames[3] "Find-Script didn't find the exact script which has dependencies, $($res4.Dependencies | Out-String)"
        AssertEquals $res4.Dependencies.MinimumVersion $Versions[3] "Find-Script returned incorrect minimum version, $($res4.Dependencies | Out-String)"
        AssertNullOrEmpty $res4.Dependencies.MaximumVersion "Maximum version should not exist, $($res4.Dependencies | Out-String)"
        AssertNullOrEmpty $res4.Dependencies.RequiredVersion "Required version should not exist, $($res4.Dependencies | Out-String)"
    }

    
    
    
    
    
    
    It "PublishScriptWithPath" {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishScriptWithRelativePath" {
        $currentLocation = Get-Location
        try
        {
            Split-Path -Path $script:PublishScriptFilePath | Set-Location

            $ScriptPath = Join-Path -Path '.' -ChildPath "$script:PublishScriptName.ps1"
            Publish-Script -Path $ScriptPath -NuGetApiKey $script:ApiKey
            $psgetItemInfo = Find-Script $script:PublishScriptName
            Assert ($psgetItemInfo.Name -eq $script:PublishScriptName) "Publish-Script should publish a script with valid relative path, $($psgetItemInfo.Name)"
        }
        finally
        {
            $currentLocation | Set-Location
        }
    }

    
    
    
    
    
    
    It "PublishScriptWithLiteralPath" {
        Copy-Item -Path $script:PublishScriptFilePath -Destination $script:TempScriptsLiteralPath
        $scriptFilePath = Join-Path -Path $script:TempScriptsLiteralPath -ChildPath "$script:PublishScriptName.ps1"
        Assert (Test-Path -LiteralPath $scriptFilePath -PathType Leaf) "$scriptFilePath is not available"
        $LiteralPath = Join-Path -Path $script:TempScriptsLiteralPath -ChildPath "$script:PublishScriptName.ps1"
        Publish-Script -LiteralPath $LiteralPath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishScriptWithConfirmAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=2
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Confirm"
        }
        finally
        {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $shouldProcessMessage = $script:LocalizedData.PublishScriptwhatIfMessage -f ($script:PublishScriptVersion, $script:PublishScriptName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish script confirm prompt is not working, $content"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion}`
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "PublishScriptWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -Confirm"
        }
        finally
        {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $shouldProcessMessage = $script:LocalizedData.PublishScriptwhatIfMessage -f ($script:PublishScriptVersion, $script:PublishScriptName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish script confirm prompt is not working, $content"

        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a valid script after confirming YES, $($psgetItemInfo.Name)"
        AssertEquals $psgetItemInfo.Version $script:PublishScriptVersion "Publish-Script should publish a valid script after confirming YES, $($psgetItemInfo.Version)"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "PublishScriptWithWhatIf" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -WhatIf"
        }
        finally
        {
            $fileName = "WriteLine-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $shouldProcessMessage = $script:LocalizedData.PublishScriptwhatIfMessage -f ($script:PublishScriptVersion, $script:PublishScriptName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish script whatif message is missing, $content"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion}`
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It PublishScriptWithXMLSpecialCharacters {
        $version = '1.9.0'
        $ScriptName = "Script-WithSpecialChars"
        $ScriptFilePath = Join-Path -Path $script:TempScriptsLiteralPath -ChildPath "$ScriptName.ps1"

        $Description = "$ScriptName script <TestElement> $&*!()[]{}@
        $ReleaseNotes = @("$ScriptName release notes", "<TestElement> $&*!()[]{}@
        $Tags = "PSGet","Special$&*!()[]{}@
        $ProjectUri = "https://$ScriptName.com/Project"
        $IconUri = "https://$ScriptName.com/Icon"
        $LicenseUri = "https://$ScriptName.com/license"
        $Author = "Author
        $CompanyName = "CompanyName <TestElement>$&*!()[]{}@
        $CopyRight = "CopyRight <TestElement>$&*!()[]{}@
        $Guid = [Guid]::NewGuid()

        $null = New-ScriptFileInfo -Path $ScriptFilePath `
                               -version $version `
                               -Description $Description `
                               -ReleaseNotes $ReleaseNotes `
                               -Guid $Guid `
                               -Tags $Tags `
                               -ProjectUri $ProjectUri `
                               -IconUri $IconUri `
                               -LicenseUri $LicenseUri `
                               -Author $Author `
                               -CompanyName $CompanyName `
                               -CopyRight $CopyRight

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "ScriptName should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.Guid $Guid "Guid should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the published one"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the published one"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the published one"
        Assert       ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the published one ($($Tags[0]))"
        Assert       ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the published one ($($Tags[1]))"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the published one"


        Publish-Script -LiteralPath $ScriptFilePath -NuGetApiKey $script:ApiKey

        $psgetItemInfo = Find-Script $ScriptName -RequiredVersion $version

        AssertEqualsCaseInsensitive $psgetItemInfo.Name $ScriptName "ScriptName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.version $version "version should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Description $Description "Description should be same as the published one"
        AssertEqualsCaseInsensitive "$($psgetItemInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.ProjectUri $ProjectUri "ProjectUri should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Author $Author "Author should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CompanyName $CompanyName "CompanyName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CopyRight $CopyRight "CopyRight should be same as the published one"
        Assert ($psgetItemInfo.Tags -contains $($Tags[0])) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[0]))"
        Assert ($psgetItemInfo.Tags -contains $($Tags[1])) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[1]))"
        AssertEqualsCaseInsensitive $psgetItemInfo.LicenseUri $LicenseUri "LicenseUri should be same as the published one"
    }

    
    
    
    
    
    
    It ValidateTestScriptFileInfoForAllProperties {
        $version = '2.1'
        $ScriptName = "Test-Script$(Get-Random)"
        $ScriptFilePath = Join-Path -Path $script:TempScriptsPath -ChildPath "$ScriptName.ps1"

        $Description = "$ScriptName script"
        $ReleaseNotes = @('contoso script now supports following features',
                               'Feature 1',
                               'Feature 2',
                               'Feature 3',
                               'Feature 4',
                               'Feature 5')
        $ProjectUri = "https://$ScriptName.com/Project"
        $IconUri = "https://$ScriptName.com/Icon"
        $LicenseUri = "https://$ScriptName.com/license"
        $Author = 'manikb'
        $CompanyName = "Microsoft Corporation"
        $CopyRight = "(c) 2015 Microsoft Corporation. All rights reserved."

        $RequiredModules = @("Foo",
                             "Bar",
                             'RequiredModule1',
                             @{ModuleName='RequiredModule2';ModuleVersion='1.0'},
                             'ExternalModule1')
        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $RequiredModules += @{ModuleName='RequiredModule3';RequiredVersion='2.0'}
        }

        $ExternalModuleDependencies = 'Foo','Bar'
        $RequiredScriptNames = 'Start-WFContosoServer', 'Stop-ContosoServerScript', 'Restart-ContosoServerScript', "Pause-ContosoServerScript", "Remote-ContosoServerScript"
        $RequiredScripts = @(
                                $RequiredScriptNames[0],
                                "$($RequiredScriptNames[1]):1.0",
                                "$($RequiredScriptNames[2]):[1.0]",
                                "$($RequiredScriptNames[3]):[1.0,2.0]",
                                "$($RequiredScriptNames[4]):(,2.0]"
                            )
        $ExternalScriptDependencies = 'Stop-ContosoServerScript'
        $Tags = @('Tag1', 'Tag2', 'Tag3')

        $null = New-ScriptFileInfo -Path $ScriptFilePath `
                               -version $version `
                               -Description $Description `
                               -ReleaseNotes $ReleaseNotes `
                               -Tags $Tags `
                               -ProjectUri $ProjectUri `
                               -IconUri $IconUri `
                               -LicenseUri $LicenseUri `
                               -Author $Author `
                               -CompanyName $CompanyName `
                               -CopyRight $CopyRight `
                               -RequiredModules $RequiredModules `
                               -ExternalModuleDependencies $ExternalModuleDependencies `
                               -RequiredScripts $RequiredScripts `
                               -ExternalScriptDependencies $ExternalScriptDependencies

        Add-Content -Path $ScriptFilePath -Value @"

            Function $($ScriptName)_Function { "$($ScriptName)_Function" }
            Workflow $($ScriptName)_Workflow { "$($ScriptName)_Workflow" }

            $($ScriptName)_Function
            $($ScriptName)_Workflow
"@

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2]) "RequiredModules should contain $($RequiredModules[2])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[2]) "RequiredScripts should contain $($RequiredScripts[2])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[3]) "RequiredScripts should contain $($RequiredScripts[3])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[4]) "RequiredScripts should contain $($RequiredScripts[4])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"
    }

    
    
    
    
    
    
    It ValidateUpdateScriptFileInfoWithExistingValuesForAllProperties {
        $version1 = '1.0'
        $version2 = '2.1'
        $ScriptName = "Test-Script$(Get-Random)"
        $ScriptFilePath = Join-Path -Path $script:TempScriptsPath -ChildPath "$ScriptName.ps1"

        $Description = "$ScriptName script"
        $ReleaseNotes = @('contoso script now supports following features',
                               'Feature 1',
                               'Feature 2',
                               'Feature 3',
                               'Feature 4',
                               'Feature 5')
        $ProjectUri = "https://$ScriptName.com/Project"
        $IconUri = "https://$ScriptName.com/Icon"
        $LicenseUri = "https://$ScriptName.com/license"
        $Author1 = [System.Environment]::GetEnvironmentVariable('USERNAME')
        $Author2 = 'manikb'
        $CompanyName = "Microsoft Corporation"
        $CopyRight = "(c) 2015 Microsoft Corporation. All rights reserved."
        $Guid1 = [Guid]::NewGuid()
        $Guid2 = [Guid]::NewGuid()

        $RequiredModules = @("Foo",
                             "Bar",
                             'RequiredModule1',
                             @{ModuleName='RequiredModule2';ModuleVersion='1.0'},
                             'ExternalModule1')
        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $RequiredModules += @{ModuleName='RequiredModule3';RequiredVersion='2.0'}
        }

        $ExternalModuleDependencies = 'Foo','Bar'
        $RequiredScripts = 'Start-WFContosoServer', 'Stop-ContosoServerScript'
        $ExternalScriptDependencies = 'Stop-ContosoServerScript'
        $Tags = @('Tag1', 'Tag2', 'Tag3')

        $null = New-ScriptFileInfo -Path $ScriptFilePath `
                               -Guid $Guid1 `
                               -Description $Description `
                               -ReleaseNotes $ReleaseNotes `
                               -Tags $Tags `
                               -ProjectUri $ProjectUri `
                               -IconUri $IconUri `
                               -LicenseUri $LicenseUri `
                               -CompanyName $CompanyName `
                               -CopyRight $CopyRight `
                               -RequiredModules $RequiredModules `
                               -ExternalModuleDependencies $ExternalModuleDependencies `
                               -RequiredScripts $RequiredScripts `
                               -ExternalScriptDependencies $ExternalScriptDependencies

        Add-Content -Path $ScriptFilePath -Value @"

            Function $($ScriptName)_Function { "$($ScriptName)_Function" }
            Workflow $($ScriptName)_Workflow { "$($ScriptName)_Workflow" }

            $($ScriptName)_Function
            $($ScriptName)_Workflow
"@

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.Guid $Guid1 "Guid should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.version $version1 "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author1 "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2]) "RequiredModules should contain $($RequiredModules[2])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"

        $null = Update-ScriptFileInfo -Path $ScriptFilePath `
                                  -version $version2 `
                                  -Guid $Guid2 `
                                  -Description $Description `
                                  -ReleaseNotes $ReleaseNotes `
                                  -Tags $Tags `
                                  -ProjectUri $ProjectUri `
                                  -IconUri $IconUri `
                                  -LicenseUri $LicenseUri `
                                  -Author $Author2 `
                                  -CompanyName $CompanyName `
                                  -CopyRight $CopyRight `
                                  -RequiredModules $RequiredModules `
                                  -ExternalModuleDependencies $ExternalModuleDependencies `
                                  -RequiredScripts $RequiredScripts `
                                  -ExternalScriptDependencies $ExternalScriptDependencies

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.Guid $Guid2 "Guid should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.version $version2 "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author2 "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2]) "RequiredModules should contain $($RequiredModules[2])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"
    }

    
    
    
    
    
    
    It ValidateUpdateScriptFileInfoWithoutExistingValuesForAllProperties {
        $version = '2.1'
        $ScriptName = "Test-Script$(Get-Random)"
        $ScriptFilePath = Join-Path -Path $script:TempScriptsPath -ChildPath "$ScriptName.ps1"

        $Description = "$ScriptName script"
        $ReleaseNotes = @('contoso script now supports following features',
                               'Feature 1',
                               'Feature 2',
                               'Feature 3',
                               'Feature 4',
                               'Feature 5')
        $ProjectUri = "https://$ScriptName.com/Project"
        $IconUri = "https://$ScriptName.com/Icon"
        $LicenseUri = "https://$ScriptName.com/license"
        $Author = 'manikb'
        $CompanyName = "Microsoft Corporation"
        $CopyRight = "(c) 2015 Microsoft Corporation. All rights reserved."

        $RequiredModules = @("Foo",
                             "Bar",
                             'RequiredModule1',
                             @{ModuleName='RequiredModule2';ModuleVersion='1.0'},
                             'ExternalModule1')
        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $RequiredModules += @{ModuleName='RequiredModule3';RequiredVersion='2.0'}
        }

        $ExternalModuleDependencies = 'Foo','Bar'
        $RequiredScripts = 'Start-WFContosoServer', 'Stop-ContosoServerScript'
        $ExternalScriptDependencies = 'Stop-ContosoServerScript'
        $Tags = @('Tag1', 'Tag2', 'Tag3')

        $null = New-ScriptFileInfo -Path $ScriptFilePath `
                               -version $version `
                               -Author $Author `
                               -Description $Description

        Add-Content -Path $ScriptFilePath -Value @"

            Function $($ScriptName)_Function { "$($ScriptName)_Function" }
            Workflow $($ScriptName)_Workflow { "$($ScriptName)_Workflow" }

            $($ScriptName)_Function
            $($ScriptName)_Workflow
"@

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the value specified to New-ScriptFileInfo"

        $null = Update-ScriptFileInfo -Path $ScriptFilePath `
                                      -version $version `
                                      -Description $Description `
                                      -ReleaseNotes $ReleaseNotes `
                                      -Tags $Tags `
                                      -ProjectUri $ProjectUri `
                                      -IconUri $IconUri `
                                      -LicenseUri $LicenseUri `
                                      -Author $Author `
                                      -CompanyName $CompanyName `
                                      -CopyRight $CopyRight `
                                      -RequiredModules $RequiredModules `
                                      -ExternalModuleDependencies $ExternalModuleDependencies `
                                      -RequiredScripts $RequiredScripts `
                                      -ExternalScriptDependencies $ExternalScriptDependencies

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2]) "RequiredModules should contain $($RequiredModules[2])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithPassThru {
        $description = 'Test script description goes here'
        $scriptFileInfoString = New-ScriptFileInfo -Description $description -PassThru
        AssertNotNull $scriptFileInfoString "New-ScriptFileInfo only with PassThru and Descriptio is not working properly, $scriptFileInfoString"
        Assert ($scriptFileInfoString -match '


"@
        Publish-Script -LiteralPath $scriptFilePath

        Install-Script -Name $scriptName -NoPathUpdate

        $res = Get-InstalledScript -Name $scriptName
        $res | Uninstall-Script
        AssertEquals $res.Name $scriptName "Script file with manually created metadata is not working fine. $res"
    }

    It "PublishScriptWithoutDotnetCommandShouldThrowError" {
        try {
            
            Remove-NuGetExe

            AssertFullyQualifiedErrorIdEquals -Scriptblock { Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey } `
                -ExpectedFullyQualifiedErrorId 'CouldNotFindDotnetCommand,Publish-Script'
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$(-not ($IsLinux -or $IsMacOS))

    
    
    
    
    
    
    It PublishScriptWithBootstrappedNugetExe {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."
            $err = $null

            try {
                $result = Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Force
            }
            catch {
                $err = $_
            }

            AssertNull $err "$err"
            AssertNull $result "$result"
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            Assert ($currentNuGetExeVersion -gt $oldNuGetExeVersion) "Current NuGet.exe version is $currentNuGetExeVersion when it should have been greater than version $oldNuGetExeVersion."

            $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
            AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Script name was $($psgetItemInfo.Name) when it should have been $script:PublishScriptName."
            AssertEquals $psgetItemInfo.Version.ToString() $script:PublishScriptVersion "Script version was $($psgetItemInfo.Version.ToString()) when it should have been $script:PublishScriptVersion."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core')

    
    
    
    
    
    
    It PublishScriptUpgradeNugetExeAndYesToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePaths
            }

            AssertNull $result "$result"
            Assert ($content -and ($content -match 'upgrade')) "Publish script confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            Assert ($currentNuGetExeVersion -gt $oldNuGetExeVersion) "Current NuGet.exe version is $currentNuGetExeVersion when it should have been greater than version $oldNuGetExeVersion."

            $psgetItemInfo = Find-Script -Name $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
            AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Script name was $($psgetItemInfo.Name) when it should have been $script:PublishScriptName."
            AssertEquals $psgetItemInfo.Version.ToString() $script:PublishScriptVersion "Script version was $($psgetItemInfo.Version.ToString()) when it should have been $script:PublishScriptVersion."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core' -or $PSVersionTable.Version -lt '5.0.0')

    
    
    
    
    
    
    It PublishScriptInstallNugetExeAndYesToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Remove-NuGetExe
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase
            Assert ((test-path $script:ProgramDataExePath) -eq $false) "NuGet.exe did not install properly uninstall."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePaths
            }

            AssertNull $result "$result"
            Assert ($content -and ($content -match 'install')) "Publish script confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $psgetItemInfo = Find-Script -Name $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
            AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Script name was $($psgetItemInfo.Name) when it should have been $script:PublishScriptName."
            AssertEquals $psgetItemInfo.Version.ToString() $script:PublishScriptVersion "Script version was $($psgetItemInfo.Version.ToString()) when it should have been $script:PublishScriptVersion."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core' -or $PSVersionTable.Version -lt '5.0.0')

    
    
    
    
    
    
    It PublishScriptUpgradeNugetExeAndNoToPrompt {
        try {
            RemoveItem $script:PublishScriptFilePath

            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 1
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePaths
            }

            AssertNotNull $err "$err"
            AssertNull $result "$result"
            Assert ($content -and ($content -match 'upgrade')) "Publish script confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $currentNuGetExeVersion $script:OutdatedNuGetExeVersion "Current version of NuGet.exe is $currentNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $psgetItemInfo = Find-Script -Name $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion -ErrorAction SilentlyContinue
            AssertNull ($psgetItemInfo) "Script published when it should not have."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core' -or $PSVersionTable.Version -lt '5.0.0')

    
    
    
    
    
    
    It PublishScriptInstallNugetExeAndNoToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Remove-NuGetExe
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase
            Assert ((test-path $script:ProgramDataExePath) -eq $false) "NuGet.exe did not install properly uninstall."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 1
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePaths
            }

            AssertNotNull $err "$err"
            AssertNull $result "$result"
            Assert ($content -and ($content -match 'install')) "Publish module confirm prompt is not working, $content."
            AssertEquals (Test-Path $script:ProgramDataExePath) $false "NuGet.exe installed when it should not have."

            $psgetItemInfo = Find-Script -Name $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion -ErrorAction SilentlyContinue
            AssertNull ($psgetItemInfo) "Script published when it should not have."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core' -or $PSVersionTable.Version -lt '5.0.0')
}

Describe PowerShell.PSGet.PublishScriptTests.P1 -Tags 'P1','OuterLoop' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {

        $null = New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                               -Version $script:PublishScriptVersion `
                               -Author Author@contoso.com `
                               -Description 'Test script description goes here ' `
                               -Force

        Add-Content -Path $script:PublishScriptFilePath `
                    -Value "
                        Function Test-ScriptFunction { 'Test-ScriptFunction' }

                        Workflow Test-ScriptWorkflow { 'Test-ScriptWorkflow' }

                        Test-ScriptFunction
                        Test-ScriptWorkflow"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem $script:PublishScriptFilePath
        RemoveItem "$script:TempScriptsPath\*.ps1"
        RemoveItem "$script:TempScriptsLiteralPath\*"

    }

    
    
    
    
    
    
    It PublishScriptToWebbasedGalleryWithoutNuGetApiKey {
        try {
            Register-PSRepository -Name '_TempTestRepo_' -SourceLocation 'https://www.poshtestgallery.com'


            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $script:PublishScriptFilePath -Repository '_TempTestRepo_'} `
                                              -expectedFullyQualifiedErrorId 'NuGetApiKeyIsRequiredForNuGetBasedGalleryService,Publish-Script'
        }
        finally {
            Get-PSRepository -Name '_TempTestRepo_' | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    }

    It "PublishScriptWithForceAndLowerVersion" {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"

        $version = '0.9'
        Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Version $version

        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Force
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $version
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should allow publishing a script version lower than the latest available version, $($psgetItemInfo.Name)"
    }

    It "PublishScriptWithoutForceAndLowerVersion" {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"

        $version = '0.8'
        Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Version $version

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey}`
                                          -expectedFullyQualifiedErrorId 'ScriptVersionShouldBeGreaterThanGalleryVersion,Publish-Script'
    }

    
    
    
    
    
    
    It "PublishScriptWithFalseConfirm" {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Confirm:$false
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        Assert ($psgetItemInfo.Name -eq $script:PublishScriptName) "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"
    }

    It 'PublishScriptWithForceAndConfirm' {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Force -Confirm
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        Assert ($psgetItemInfo.Name -eq $script:PublishScriptName) "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"
    }

    It 'PublishScriptWithForceAndWhatIf' {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Force -WhatIf
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        Assert ($psgetItemInfo.Name -eq $script:PublishScriptName) "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"
    }

    It "PublishScriptWithoutNugetExeAndNoToPrompt" {
        try {
            
            Remove-NuGetExe

            $outputPath = $script:TempPath
            $guid =  [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake=1
            $content = $null
            $err = $null

            try
            {
                $result = ExecuteCommand $runspace "Publish-Script -Path $script:PublishScriptFilePath"
            }
            catch
            {
                $err = $_
            }
            finally
            {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if(Test-Path $path)
                {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            Assert ($err -and $err.Exception.Message.Contains('NuGet.exe')) "Prompt for installing nuget binaries is not working, $err"
            Assert ($content -and $content.Contains('NuGet.exe')) "Prompt for installing nuget binaries is not working, $content"

            AssertFullyQualifiedErrorIdEquals -Scriptblock {Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion}`
                                              -ExpectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
	    }
        finally {
            Install-NuGetBinaries
        }
    } `
    -Skip:$(
        ($PSCulture -ne 'en-US') -or
        ($PSEdition -eq 'Core') -or
        ($env:APPVEYOR_TEST_PASS -eq 'True') -or
        ([System.Environment]::OSVersion.Version -lt "6.2.9200.0")
    )

    
    
    
    
    
    
    It "PublishNotAvailableScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path (Join-Path -Path $script:TempScriptsPath -ChildPath NotAvailableScript.ps1) -NuGetApiKey $script:ApiKey} `
                                          -expectedFullyQualifiedErrorId 'PathNotFound,Publish-Script'
    }

    
    
    
    
    
    
    It "PublishInvalidScript" {
        Set-Content -Path $script:PublishScriptFilePath -Value "function foo {'foo'}; foo"
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey} `
                                            -expectedFullyQualifiedErrorId 'MissingPSScriptInfo,Test-ScriptFileInfo'
    }

    
    
    
    
    
    
    It "PublishInvalidScriptFileExtension" {
        $scriptPath = Join-Path -Path $script:TempScriptsPath -ChildPath "Temp.psm1"
        $null = New-Item -Path $scriptPath -ItemType File -Force
        Get-Content -Path $script:PublishScriptFilePath | Set-Content -Path $scriptPath -Force
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -LiteralPath $scriptPath -NuGetApiKey $script:ApiKey} `
                                            -expectedFullyQualifiedErrorId 'InvalidScriptFilePath,Publish-Script'
    }

    
    
    
    
    
    
    It "PublishToInvalidRepository" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey -Repository NonRegisteredRepo} `
                                          -expectedFullyQualifiedErrorId 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'
    }

    
    
    
    
    
    
    It "PublishScriptWithExistingVersion" {
        Publish-Script -Path $script:PublishScriptFilePath -NuGetApiKey $script:ApiKey
        $psgetItemInfo = Find-Script $script:PublishScriptName -RequiredVersion $script:PublishScriptVersion
        AssertEquals $psgetItemInfo.Name $script:PublishScriptName "Publish-Script should publish a script with valid script path, $($psgetItemInfo.Name)"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $script:PublishScriptFilePath} `
                                          -expectedFullyQualifiedErrorId 'ScriptVersionIsAlreadyAvailableInTheGallery,Publish-Script'
    }

    
    
    
    
    
    
    It "PublishInvalidScriptBasePath" {
        $invalidScriptBasePath = Join-Path -Path $script:TempScriptsPath -ChildPath InvalidScriptBase | Join-Path -ChildPath ScriptFile.ps1
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Script -Path $invalidScriptBasePath} `
                                            -expectedFullyQualifiedErrorId "PathNotFound,Publish-Script"
    }

    
    
    
    
    
    
    It ValidateUpdateScriptFileInfoWithoutAnyNewValues {
        $version = '2.1'
        $ScriptName = "Test-Script$(Get-Random)"
        $ScriptFilePath = Join-Path -Path $script:TempScriptsPath -ChildPath "$ScriptName.ps1"

        $Description = "$ScriptName script"
        $ReleaseNotes = @('contoso script now supports following features',
                               'Feature 1',
                               'Feature 2',
                               'Feature 3',
                               'Feature 4',
                               'Feature 5')
        $ProjectUri = "https://$ScriptName.com/Project"
        $IconUri = "https://$ScriptName.com/Icon"
        $LicenseUri = "https://$ScriptName.com/license"
        $Author = 'manikb'
        $CompanyName = "Microsoft Corporation"
        $CopyRight = "(c) 2015 Microsoft Corporation. All rights reserved."

        $RequiredModule2 = @{ModuleName='RequiredModule2'; ModuleVersion='1.0'; Guid='653c6268-3575-4456-b7c8-6edb9e5e80c5'}
        $RequiredModules = @("Foo",
                             "Bar",
                             @{ModuleName='RequiredModule1'; ModuleVersion='1.0'},
                             $RequiredModule2,
                             'ExternalModule1')
        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $RequiredModules += @{ModuleName='RequiredModule3';RequiredVersion='2.0'}
        }

        $ExternalModuleDependencies = 'Foo','Bar'
        $RequiredScripts = 'Start-WFContosoServer', 'Stop-ContosoServerScript'
        $ExternalScriptDependencies = 'Stop-ContosoServerScript'
        $Tags = @('Tag1', 'Tag2', 'Tag3')

        $null = New-ScriptFileInfo -Path $ScriptFilePath `
                               -version $version `
                               -Description $Description `
                               -ReleaseNotes $ReleaseNotes `
                               -Tags $Tags `
                               -ProjectUri $ProjectUri `
                               -IconUri $IconUri `
                               -LicenseUri $LicenseUri `
                               -Author $Author `
                               -CompanyName $CompanyName `
                               -CopyRight $CopyRight `
                               -RequiredModules $RequiredModules `
                               -ExternalModuleDependencies $ExternalModuleDependencies `
                               -RequiredScripts $RequiredScripts `
                               -ExternalScriptDependencies $ExternalScriptDependencies

        Add-Content -Path $ScriptFilePath -Value @"

            Function $($ScriptName)_Function { "$($ScriptName)_Function" }
            Workflow $($ScriptName)_Workflow { "$($ScriptName)_Workflow" }

            $($ScriptName)_Function
            $($ScriptName)_Workflow
"@

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2].ModuleName) "RequiredModules should contain $($RequiredModules[2].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        AssertEquals $scriptInfo.RequiredModules[3].Name $RequiredModule2.ModuleName "RequiredModules should contain $($RequiredModule2.ModuleName)"
        AssertEquals $scriptInfo.RequiredModules[3].Version $RequiredModule2.ModuleVersion "RequiredModules should contain $($RequiredModule2.ModuleVersion)"
        AssertEquals $scriptInfo.RequiredModules[3].Guid $RequiredModule2.Guid "RequiredModules should contain $($RequiredModule2.Guid)"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"

        $null = Update-ScriptFileInfo -Path $ScriptFilePath

        $scriptInfo = Test-ScriptFileInfo -LiteralPath $ScriptFilePath

        AssertEqualsCaseInsensitive $scriptInfo.Path $ScriptFilePath "Path should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ScriptBase $script:TempScriptsPath "ScriptBase should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Name $ScriptName "Name should be same as the value specified to New-ScriptFileInfo"

        AssertEqualsCaseInsensitive $scriptInfo.version $version "version should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Description $Description "Description should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.ProjectUri $ProjectUri "ProjectUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.IconUri $IconUri "IconUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.LicenseUri $LicenseUri "LicenseUri should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.Author $Author "Author should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CompanyName $CompanyName "CompanyName should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive $scriptInfo.CopyRight $CopyRight "CopyRight should be same as the value specified to New-ScriptFileInfo"
        AssertEqualsCaseInsensitive "$($scriptInfo.ReleaseNotes)" "$ReleaseNotes" "ReleaseNotes should be same as the value specified to New-ScriptFileInfo"

        Assert ($scriptInfo.Tags -contains $($Tags[0])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[0]))"
        Assert ($scriptInfo.Tags -contains $($Tags[1])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[1]))"
        Assert ($scriptInfo.Tags -contains $($Tags[2])) "Tags ($($scriptInfo.Tags)) should contain the value specified to New-ScriptFileInfo ($($Tags[2]))"

        AssertEquals $scriptInfo.RequiredModules.Count $RequiredModules.Count "Invalid RequiredModules count"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[0]) "RequiredModules should contain $($RequiredModules[0])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[1]) "RequiredModules should contain $($RequiredModules[1])"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[2].ModuleName) "RequiredModules should contain $($RequiredModules[2].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[3].ModuleName) "RequiredModules should contain $($RequiredModules[3].ModuleName)"
        Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[4]) "RequiredModules should contain $($RequiredModules[4])"

        AssertEquals $scriptInfo.RequiredModules[3].Name $RequiredModule2.ModuleName "RequiredModules should contain $($RequiredModule2.ModuleName)"
        AssertEquals $scriptInfo.RequiredModules[3].Version $RequiredModule2.ModuleVersion "RequiredModules should contain $($RequiredModule2.ModuleVersion)"
        AssertEquals $scriptInfo.RequiredModules[3].Guid $RequiredModule2.Guid "RequiredModules should contain $($RequiredModule2.Guid)"

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            Assert ($scriptInfo.RequiredModules.Name -contains $RequiredModules[5].ModuleName) "RequiredModules should contain $($RequiredModules[5].ModuleName)"
        }

        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[0]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[0])"
        Assert ($scriptInfo.ExternalModuleDependencies -contains $ExternalModuleDependencies[1]) "ExternalModuleDependencies should contain $($ExternalModuleDependencies[1])"

        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[0]) "RequiredScripts should contain $($RequiredScripts[0])"
        Assert ($scriptInfo.RequiredScripts -contains $RequiredScripts[1]) "RequiredScripts should contain $($RequiredScripts[1])"

        Assert ($scriptInfo.ExternalScriptDependencies -contains $ExternalScriptDependencies) "ExternalScriptDependencies should contain $ExternalScriptDependencies"

        Assert ($scriptInfo.DefinedWorkflows -contains "$($ScriptName)_Workflow") "DefinedWorkflows should contain $($ScriptName)_Workflow"
        Assert ($scriptInfo.DefinedFunctions -contains "$($ScriptName)_Function") "DefinedWorkflows should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Function") "DefinedCommands should contain $($ScriptName)_Function"
        Assert ($scriptInfo.DefinedCommands -contains "$($ScriptName)_Workflow") "DefinedCommands should contain $($ScriptName)_Workflow"
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithoutPathAndPassThru {
        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId 'MissingTheRequiredPathOrPassThruParameter,New-ScriptFileInfo' `
                                          -scriptblock { New-ScriptFileInfo -Description 'Test script description goes here' }
    }

    
    
    
    
    
    
    It UpdateScriptFileInfoWithoutScriptInfo {
        Set-Content -path $script:PublishScriptFilePath -Value " "
        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId 'MissingPSScriptInfo,Test-ScriptFileInfo' `
                                          -scriptblock { Update-ScriptFileInfo -Path $script:PublishScriptFilePath }
    }

    
    
    
    
    
    
    It UpdateScriptFileInfoWithForceAndWithoutScriptInfo {
        Set-Content -path $script:PublishScriptFilePath -Value " "
        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId 'DescriptionParameterIsMissingForAddingTheScriptFileInfo,Update-ScriptFileInfo' `
                                          -scriptblock { Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Force }
    }

    
    
    
    
    
    
    It UpdateScriptFileInfoWithForce_Description_WithoutScriptInfo1 {
        $Description = 'Temp Script file desctiption'
        Set-Content -path $script:PublishScriptFilePath -Value " "
        Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Force -Description $Description

        $scriptInfo = Test-ScriptFileInfo -Path $script:PublishScriptFilePath
        AssertNotNull $scriptInfo "Update-ScriptFileInfo should add the metadata to an empty file."
        AssertEquals $scriptInfo.Description $Description  "Update-ScriptFileInfo should add the metadata to an empty file."
    }

    
    
    
    
    
    
    It UpdateScriptFileInfoWithForce_Description_WithoutScriptInfo2 {
        $Description = 'Temp Script file desctiption'
        Set-Content -path $script:PublishScriptFilePath -Value @'
Function foo {
"Foo"
}

Foo
'@
        Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Force -Description $Description

        $scriptInfo = Test-ScriptFileInfo -Path $script:PublishScriptFilePath
        AssertNotNull $scriptInfo "Update-ScriptFileInfo should add the metadata to an empty file."
        AssertEquals $scriptInfo.Description $Description  "Update-ScriptFileInfo should add the metadata to an empty file."
    }

    
    
    
    
    
    
    It UpdateScriptFileInfoWithForce_Description_WithHelpComment {
        $Description = 'Temp Script file desctiption'
        Set-Content -path $script:PublishScriptFilePath -Value @'

Param()

Function foo
{
"Foo"
}

Foo
'@
        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId 'UnableToAddPSScriptInfo,Update-ScriptFileInfo' `
                                          -scriptblock { Update-ScriptFileInfo -Path $script:PublishScriptFilePath -Force -Description $Description}
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithInvalidLicenseUri {

        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId "InvalidWebUri,Test-ScriptFileInfo" `
                                          -scriptblock {
                                                         New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                                                                        -Version $script:PublishScriptVersion `
                                                                        -Author Author@contoso.com `
                                                                        -Description 'Test script description goes here ' `
                                                                        -LicenseUri "\\ma" `
                                                                        -Force
                                                        }
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithInvalidIconUri {

        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId "InvalidWebUri,Test-ScriptFileInfo" `
                                          -scriptblock {
                                                         New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                                                                        -Version $script:PublishScriptVersion `
                                                                        -Author Author@contoso.com `
                                                                        -Description 'Test script description goes here ' `
                                                                        -IconUri "\\localmachine\MyIcon.png" `
                                                                        -Force
                                                        }
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithInvalidProjectUri {

        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId "InvalidWebUri,Test-ScriptFileInfo" `
                                          -scriptblock {
                                                         New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                                                                        -Version $script:PublishScriptVersion `
                                                                        -Author Author@contoso.com `
                                                                        -Description 'Test script description goes here ' `
                                                                        -ProjectUri "MyProject.com" `
                                                                        -Force
                                                        }
    }

    
    
    
    
    
    
    It NewScriptFileInfoWithExistingFile {

        AssertFullyQualifiedErrorIdEquals -expectedFullyQualifiedErrorId 'ScriptFileExist,New-ScriptFileInfo' `
                                          -scriptblock {
                                                         New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                                                                        -Version $script:PublishScriptVersion `
                                                                        -Author Author@contoso.com `
                                                                        -Description 'Test script description goes here '
                                                        }
    }

    
                                                                        -Force
                                                        }
    }

    
                                                                        -Description 'Test script description goes here ' `
                                                                        -Force
                                                        }
    }
}

Describe PowerShell.PSGet.PublishScriptTests.P2 -Tags 'P2','OuterLoop' {
    
    
    if($IsMacOS -or $IsLinux) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {

        $null = New-ScriptFileInfo -Path $script:PublishScriptFilePath `
                               -Version $script:PublishScriptVersion `
                               -Author Author@contoso.com `
                               -Description 'Test script description goes here ' `
                               -Force

        Add-Content -Path $script:PublishScriptFilePath `
                    -Value "
                        Function Test-ScriptFunction { 'Test-ScriptFunction' }

                        Workflow Test-ScriptWorkflow { 'Test-ScriptWorkflow' }

                        Test-ScriptFunction
                        Test-ScriptWorkflow"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem $script:PublishScriptFilePath
        RemoveItem "$script:TempScriptsPath\*.ps1"
        RemoveItem "$script:TempScriptsLiteralPath\*"

    }

    
    
    
    
    
    
    
    
    
    It PublishscriptWithExternalDependencies {
        $repoName = "PSGallery"
        $ScriptName = "Script-WithDependencies1"

        $RequiredModuleNames = @("RequiredModule1", "RequiredModule2")
        $ExternalModuleDependencies = @('ExternalRequiredModule1', 'ExternalRequiredModule2')

        $RequiredModules1 = @('RequiredModule1',
                              'ExternalRequiredModule1',
                              'ExternalRequiredModule2',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '1.5'; })

        $RequiredModules2 = @('RequiredModule1',
                              'ExternalRequiredModule1',
                              'ExternalRequiredModule2',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '2.0'; })

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            $RequiredModuleNames += @("RequiredModule3")

            $RequiredModules1 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.0'; }
            $RequiredModules2 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.5'; }
        }

        
        CreateAndPublishTestModule -ModuleName "RequiredModule1" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        CreateAndPublishTestModule -ModuleName "RequiredModule2" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        CreateAndPublishTestModule -ModuleName "RequiredModule3" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        $testScriptNames = @(
                                'Required-Script1',
                                'Required-Script2',
                                'Required-Script3',
                                'Script-WithDependencies1',
                                'Script-WithDependencies2'
                            )

        $RequiredScripts1 = @(
                                'Required-Script1',
                                'Required-Script2',
                                'ExternalRequired-Script1',
                                'ExternalRequired-Script2'
                             )

        $RequiredScripts2 = @(
                                'Required-Script1',
                                'Required-Script2',
                                'Required-Script3',
                                'ExternalRequired-Script1',
                                'ExternalRequired-Script2'
                             )

        $ExternalScriptDependencies = @('ExternalRequired-Script1', 'ExternalRequired-Script2')

        foreach($testScriptName in $testScriptNames)
        {
            if($testScriptName.StartsWith($ScriptName, [System.StringComparison]::OrdinalIgnoreCase))
            {
                CreateAndPublish-TestScript -Name $testScriptName `
                                            -Version '1.0' `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName `
                                            -RequiredModules $RequiredModules1 `
                                            -ExternalModuleDependencies $ExternalModuleDependencies `
                                            -RequiredScripts $RequiredScripts1 `
                                            -ExternalScriptDependencies $ExternalScriptDependencies

                CreateAndPublish-TestScript -Name $testScriptName `
                                            -Version '2.0' `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName `
                                            -RequiredModules $RequiredModules2 `
                                            -ExternalModuleDependencies $ExternalModuleDependencies `
                                            -RequiredScripts $RequiredScripts2 `
                                            -ExternalScriptDependencies $ExternalScriptDependencies
            }
            else
            {
                CreateAndPublish-TestScript -Name $testScriptName `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName
            }
        }

        $res1 = Find-Script -Name $ScriptName -RequiredVersion '1.0'
        AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"
        Assert ($res1.Dependencies.Name.Count -ge ($DepencyModuleNames.Count+$RequiredScripts.Count+1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

        $res2 = Find-Script -Name $ScriptName -RequiredVersion '2.0'
        AssertEquals $res2.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res2"
        Assert ($res2.Dependencies.Name.Count -ge ($DepencyModuleNames.Count+$RequiredScripts.Count+1)) "Find-Script with -IncludeDependencies returned wrong results, $res4"
    }

    
    
    
    
    
    
    
    
    It PublishScriptWithDependencies {
        $repoName = "PSGallery"
        $ScriptName = "Script-WithDependencies1"

        $RequiredModuleNames = @("RequiredModule1", "RequiredModule2")

        $RequiredModules1 = @('RequiredModule1',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '1.5'; })

        $RequiredModules2 = @('RequiredModule1',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '2.0'; })

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            $RequiredModuleNames += @("RequiredModule3")

            $RequiredModules1 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.0'; }
            $RequiredModules2 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.5'; }
        }

        
        CreateAndPublishTestModule -ModuleName "RequiredModule1" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        CreateAndPublishTestModule -ModuleName "RequiredModule2" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        CreateAndPublishTestModule -ModuleName "RequiredModule3" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName

        $testScriptNames = @(
                                'Required-Script1',
                                'Required-Script2',
                                'Required-Script3',
                                'Script-WithDependencies1',
                                'Script-WithDependencies2'
                            )

        $RequiredScripts1 = @(
                                'Required-Script1',
                                'Required-Script2'
                             )

        $RequiredScripts2 = @(
                                'Required-Script1',
                                'Required-Script2',
                                'Required-Script3'
                             )

        foreach($testScriptName in $testScriptNames)
        {
            if($testScriptName.StartsWith($ScriptName, [System.StringComparison]::OrdinalIgnoreCase))
            {
                CreateAndPublish-TestScript -Name $testScriptName `
                                            -Version '1.0' `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName `
                                            -RequiredModules $RequiredModules1 `
                                            -RequiredScripts $RequiredScripts1

                CreateAndPublish-TestScript -Name $testScriptName `
                                            -Version '2.0' `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName `
                                            -RequiredModules $RequiredModules2 `
                                            -RequiredScripts $RequiredScripts2
            }
            else
            {
                CreateAndPublish-TestScript -Name $testScriptName `
                                            -NuGetApiKey $ApiKey `
                                            -Repository $repoName
            }
        }

        $res1 = Find-Script -Name $ScriptName -RequiredVersion '1.0'
        AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"
        Assert ($res1.Dependencies.Name.Count -ge ($DepencyModuleNames.Count+$RequiredScripts.Count+1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

        $res2 = Find-Script -Name $ScriptName -RequiredVersion '2.0'
        AssertEquals $res2.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res2"
        Assert ($res2.Dependencies.Name.Count -ge ($DepencyModuleNames.Count+$RequiredScripts.Count+1)) "Find-Script with -IncludeDependencies returned wrong results, $res4"
    }
}

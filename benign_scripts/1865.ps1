


Describe "Tests Get-Command with relative paths and wildcards" -Tag "CI" {

    BeforeAll {
        
        $file1 = Setup -f WildCardCommandA.exe -pass
        $file2 = Setup -f WildCardCommand[B].exe -pass
        
        
        if ( $IsLinux -or $IsMacOS ) {
            /bin/chmod 777 "$file1"
            /bin/chmod 777 "$file2"
        }
        $commandInfo = Get-Command Get-Date -ShowCommandInfo
    }

    
    It "Test wildcard with drive relative directory path" -Skip:(!$IsWindows) {
        $pathName = Join-Path $TestDrive "WildCardCommandA*"
        $driveOffset = $pathName.IndexOf(":")
        $driveName = $pathName.Substring(0,$driveOffset + 1)
        Push-Location -Path $driveName
        try {
            $pathName = $pathName.Substring($driveOffset + 1)
            $result = Get-Command -Name $pathName
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be WildCardCommandA.exe
        }
        catch {
            Pop-Location
        }
    }

    It "Test wildcard with relative directory path" {
        push-location $TestDrive
        $result = Get-Command -Name .\WildCardCommandA*
        pop-location
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Be WildCardCommandA.exe
    }

    It "Test with PowerShell wildcard and relative path" {
        push-location $TestDrive

        
        $result = Get-Command -Name .\WildCardCommand[A].exe
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Be WildCardCommandA.exe

        
        $result = Get-Command -Name .\WildCardCommand[B].exe
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Be WildCardCommand[B].exe

        Pop-Location
    }

    It "Get-Command -ShowCommandInfo property field test" {
        $properties = ($commandInfo | Get-Member -MemberType NoteProperty)
        $propertiesAsString =  $properties.name | out-string
        $propertiesAsString | Should -MatchExactly 'CommandType'
        $propertiesAsString | Should -MatchExactly 'Definition'
        $propertiesAsString | Should -MatchExactly 'Module'
        $propertiesAsString | Should -MatchExactly 'ModuleName'
        $propertiesAsString | Should -MatchExactly 'Name'
        $propertiesAsString | Should -MatchExactly 'ParameterSets'
    }

    $testcases = @(
                  @{observed = $commandInfo.Name; testname = "Name"; result = "Get-Date"}
                  @{observed = $commandInfo.ModuleName; testname = "Name"; result = "Microsoft.PowerShell.Utility"}
                  @{observed = $commandInfo.Module.Name; testname = "ModuleName"; result = "Microsoft.PowerShell.Utility"}
                  @{observed = $commandInfo.CommandType; testname = "CommandType"; result = "Cmdlet"}
                  @{observed = $commandInfo.Definition.Count; testname = "Definition"; result = 1}
               )

    It "Get-Command -ShowCommandInfo property test - <testname>" -TestCases $testcases{
            param (
            $observed,
            $result
        )
        $observed | Should -BeExactly $result
    }

    It "Get-Command -ShowCommandInfo ParameterSets property field test" {
        $properties = ($commandInfo.ParameterSets[0] | Get-Member -MemberType NoteProperty)
        $propertiesAsString =  $properties.name | out-string
        $propertiesAsString | Should -MatchExactly 'IsDefault'
        $propertiesAsString | Should -MatchExactly 'Name'
        $propertiesAsString | Should -MatchExactly 'Parameters'
    }

    It "Get-Command -ShowCommandInfo Parameters property field test" {
        $properties = ($commandInfo.ParameterSets[0].Parameters | Get-Member -MemberType NoteProperty)
        $propertiesAsString =  $properties.name | out-string
        $propertiesAsString | Should -MatchExactly 'HasParameterSet'
        $propertiesAsString | Should -MatchExactly 'IsMandatory'
        $propertiesAsString | Should -MatchExactly 'Name'
        $propertiesAsString | Should -MatchExactly 'ParameterType'
        $propertiesAsString | Should -MatchExactly 'Position'
        $propertiesAsString | Should -MatchExactly 'ValidParamSetValues'
        $propertiesAsString | Should -MatchExactly 'ValueFromPipeline'
    }

}

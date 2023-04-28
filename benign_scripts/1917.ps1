

Describe "Get-PSCallStack DRT Unit Tests" -Tags "CI" {
    BeforeAll {
        $scriptFileName = "GetTryCatchCallStack.ps1"
        $scriptFilePath = Join-Path $TestDrive -ChildPath $scriptFileName
    }
    It "Verifies that the script block of a catch clause does not show up on the call stack" {
        $fileStream = @"
        function foo()
        {
            try
            {
                throw 1
            }
            catch
            {
                bar
            }
        }

        function bar()
        {
            try
            {
                throw 1
            }
            catch
            {
                try
                {
                    throw 1
                }
                catch
                {
                    Get-PSCallStack
                }
            }
        }

        foo
"@

        $fileStream > $scriptFilePath

        $results = & "$scriptFilePath"
        $results.Count | Should -BeGreaterThan 3
        $results[0].Command | Should -BeExactly "bar"
        $results[0].ScriptName | Should -Be $scriptFilePath
        $results[0].ScriptLineNumber | Should -Be 27
        $results[0].InvocationInfo.ScriptLineNumber | Should -Be 9

        $results[1].Command | Should -BeExactly "foo"
        $results[1].ScriptName | Should -Be $scriptFilePath
        $results[1].ScriptLineNumber | Should -Be 9
        $results[1].InvocationInfo.ScriptLineNumber | Should -Be 32

        
        $results[2].Command | Should -Be $scriptFileName
        $results[2].ScriptName | Should -Be $scriptFilePath
        $results[2].ScriptLineNumber | Should -Be 32
        $results[2].InvocationInfo.ScriptLineNumber | Should -Be 46
    }

    It "Verify that the script block of a trap statement shows up on the call stack" {
        $fileStream = @"
        trap
        {
            Get-PSCallStack
            continue
        }

        throw 1
"@

        $fileStream > $scriptFilePath
        $results = & "$scriptFilePath"
        $results.Count | Should -BeGreaterThan 2
        $results[0].Command | Should -Be $scriptFileName
        $results[0].ScriptName | Should -Be $scriptFilePath
        $results[0].ScriptLineNumber | Should -Be 3
        $results[0].InvocationInfo.ScriptLineNumber | Should -Be 77

        $results[1].Command | Should -Be $scriptFileName
        $results[1].ScriptName | Should -Be $scriptFilePath
        $results[1].ScriptLineNumber | Should -Be 7
        $results[1].InvocationInfo.ScriptLineNumber | Should -Be 77
    }
}

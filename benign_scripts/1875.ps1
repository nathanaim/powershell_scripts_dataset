

Describe "Stream writer tests" -Tags "CI" {
    $targetfile = Join-Path -Path $TestDrive -ChildPath "writeoutput.txt"

    
    
    function Write-Messages
    {
        [CmdletBinding()]

        param()

        Write-Verbose "Verbose message"

        Write-Debug "Debug message"

    }

    Context "Redirect Stream Tests" {
        

        AfterEach { Remove-Item $targetfile }
        It "Should write warnings to the warning stream" {
            Write-Warning "Test Warning" 3>&1 > $targetfile

            Get-Content $targetfile | Should -BeExactly "Test Warning"
        }

        It "Should write error messages to the error stream" {
            Write-Error "Testing Error" 2>&1 > $targetfile
            
            $targetfile | Should -FileContentMatch ": Testing Error"
        }

        It "Should write debug messages to the debug stream" {
            Write-Messages -Debug -ErrorAction SilentlyContinue 5>&1 > $targetfile
            
            $targetfile | Should -FileContentMatch "Debug Message"
        }

        It "Should write messages to the verbose stream" {
            Write-Messages -Verbose 4>&1 > $targetfile
            
            $targetfile | Should -FileContentMatch "Verbose Message"
        }
    }

    Context "Error automatic variable" {
        It "Should write error messages to the `$Error automatic variable" {
            Write-Error "Test Error Message" -ErrorAction SilentlyContinue

            $Error[0] | Should -Match "Test Error Message"
        }
    }

    Context "Write-Information cmdlet" {
        BeforeAll {
            $ps = [powershell]::Create()

            $testInfoData = @(
                @{ Name = 'defaults'; Command = "Write-Information TestMessage";              returnCount = 1; returnValue = 'TestMessage' }
                @{ Name = '-Object';  Command = "Write-Information -MessageData TestMessage"; returnCount = 1; returnValue = 'TestMessage' }
                @{ Name = '-Message'; Command = "Write-Information -Message TestMessage";     returnCount = 1; returnValue = 'TestMessage' }
                @{ Name = '-Msg';     Command = "Write-Information -Msg TestMessage";         returnCount = 1; returnValue = 'TestMessage' }
                @{ Name = '-Tag';     Command = "Write-Information TestMessage -Tag Test";    returnCount = 1; returnValue = 'TestMessage' }
            )
        }

        BeforeEach {
            $ps.Commands.Clear()
            $ps.Streams.ClearStreams()
        }

        AfterAll {
            $ps.Dispose()
        }

       It "Write-Information outputs an information object" {
            
            $result = Write-Information "Test Message" *>&1
            $result.NativeThreadId | Should -Not -Be 0
            $result.ProcessId | Should -Be $pid
            $result | Should -BeOfType System.Management.Automation.InformationRecord

            
            $result.Computer | Should -Match "^($([environment]::MachineName)){1}(\.[a-zA-Z0-9]+)*$|^localhost$"
            if ($IsWindows)
            {
                $result.User | Should -Match ".*${env:USERNAME}"
            }
            else
            {
                $result.User | Should -Be $(whoami)
            }

            "$result" | Should -BeExactly "Test Message"
       }

       It "Write-Information accept objects from pipe" {
            $ps.AddScript("'teststring',12345 | Write-Information -InformationAction Continue").Invoke()
            $result = $ps.Streams.Information
            $result.Count | Should -Be 2
            $result[0].MessageData | Should -BeExactly "teststring"
            $result[1].MessageData | Should -BeExactly "12345"
       }

       It "Write-Information works with <Name>" -TestCases:$testInfoData {
            param($Command, $returnCount, $returnValue)
            $ps.AddScript($Command).Invoke()

            $result = $ps.Streams.Information

            $result.Count | Should -Be $returnCount
            (Compare-Object $result $returnValue -SyncWindow 0).length | Should -Be 0
        }

        It "Write-Information accepts `$Null" {
            $streamPath = Join-Path $testdrive information.txt
            $null | Write-Information -Tags myTag -ErrorAction Stop -InformationAction SilentlyContinue -InformationVariable i
            $i.Tags | Should -BeExactly "myTag"
            $i.MessageData | Should -Be $null
        }
    }
}

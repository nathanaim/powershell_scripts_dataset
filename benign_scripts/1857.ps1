

Describe "Out-Default Tests" -tag CI {
    BeforeAll {
        
        
        
        $powershell = "$PSHOME/pwsh"
    }

    It "'Out-Default -Transcript' shows up in transcript, but not host" {
        $script = @"
            `$null = Start-Transcript -Path "$testdrive\transcript.txt";
            'hello' | Microsoft.PowerShell.Core\Out-Default -Transcript;
            'bye';
            `$null = Stop-Transcript
"@

        & $powershell -noprofile -command $script | Should -BeExactly 'bye'
        "TestDrive:\transcript.txt" | Should -FileContentMatch 'hello'
    }

    It "Out-Default reverts transcription state when used more than once in a pipeline" {
        & $powershell -noprofile -command "Out-Default -Transcript | Out-Default -Transcript; 'Hello'" | Should -BeExactly "Hello"
    }

    It "Out-Default reverts transcription state when exception occurs in pipeline" {
        & $powershell -noprofile -command "try { & { throw } | Out-Default -Transcript } catch {}; 'Hello'" | Should -BeExactly "Hello"
    }

    It "Out-Default reverts transcription state even if Dispose() isn't called" {
        $script = @"
            `$sp = {Out-Default -Transcript}.GetSteppablePipeline();
            `$sp.Begin(`$false);
            `$sp = `$null;
            [GC]::Collect();
            [GC]::WaitForPendingFinalizers();
            'hello'
"@
        & $powershell -noprofile -command $script | Should -BeExactly 'hello'
    }
}

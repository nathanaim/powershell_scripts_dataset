











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$ps3Installed = $false
$PSVersion,$CLRVersion = powershell -NoProfile -NonInteractive -Command { $PSVersionTable.PSVersion ; $PSVersionTable.CLRVersion }
$getPsVersionTablePath = Join-Path -Path $PSScriptRoot -ChildPath 'PowerShell\Get-PSVersionTable.ps1' -Resolve


$setExecPolicyScriptBlock = { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned }
Invoke-CPowerShell -ScriptBlock $setExecPolicyScriptBlock
Invoke-CPowerShell -ScriptBlock $setExecPolicyScriptBlock -x86

function Assert-EnvVarCleanedUp
{
    It 'should clean up environment' {
        ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath')) | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running a ScriptBlock' {
    $command = {
        param(
            $Argument
        )
            
        $Argument
    }
        
    $result = Invoke-PowerShell -ScriptBlock $command -Args 'Hello World!'
    It 'should execute the scriptblock' {
        $result | Should Be 'Hello world!'
    }
}
    
Describe 'Invoke-PowerShell.when running a 32-bit PowerShell' {
    $command = {
        $env:PROCESSOR_ARCHITECTURE
    }
        
    $result = Invoke-PowerShell -ScriptBlock $command -x86
    It 'should run under x86' {
        $result | Should Be 'x86'
    }
}
    
if( Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3 )
{
    if( $Host.Name -eq 'Windows PowerShell ISE Host' )
    {
        Describe 'Invoke-PowerShell.when in the ISE host and running a scripb block under PowerShell 2' {
            $command = {
                $PSVersionTable.CLRVersion
            }
        
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 -ErrorAction SilentlyContinue
            It 'should write an error' {
                $error.Count | Should Be 1
            }

            It 'should not execute the script block' {
                $result | Should BeNullOrEmpty
            }

            Assert-EnvVarCleanedUp
        }
    }
    else
    {
        Describe 'Invoke-PowerShell.when in the console host and running a script blcok under PowerShell 2' {
            if( (Test-Path -Path 'env:APPVEYOR') )
            {
                return
            }

            It '(the test) should make sure .NET 2 is installed' {
                (Test-DotNet -V2) | Should Be $true
            }
            $command = {
                $PSVersionTable.CLRVersion
            }
        
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 
            It 'should not write an error' {
                $error.Count | Should Be 0
            }

            It 'should execute the script block' {
                $result | Should Not BeNullOrEmpty
                $result.Major | Should Be 2
            }

            Assert-EnvVarCleanedUp
        }
    }
}
    
Describe 'Invoke-PowerShell.when running a command under PowerShell 4' {
    $command = {
        $PSVersionTable.CLRVersion
    }
        
    $result = Invoke-PowerShell -Command $command -Runtime v4.0
    It 'should run the command' {
        $result.Major | Should Be 4
    }

    Assert-EnvVarCleanedUp
}
    
if( (Test-OSIs64Bit) )
{
    Describe 'Invoke-PowerShell.when running x86 PowerShell' {
        $error.Clear()
        if( (Test-PowerShellIs32Bit) )
        {
            $result = Invoke-PowerShell -ScriptBlock { $env:PROCESSOR_ARCHITECTURE }
        }
        else
        {
            $command = @"
& "$(Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)"

if( -not (Test-PowerShellIs32Bit) )
{
    throw 'Not in 32-bit PowerShell!'
}
Invoke-PowerShell -ScriptBlock { `$env:PROCESSOR_ARCHITECTURE }
"@
            $result = Invoke-PowerShell -Command $command -Encode -x86
        }

        It 'should not write an error' {
            $error.Count | Should Be 0
        }

        It 'should execute the scriptblock' {
            $result | Should Be 'AMD64'
        }
    }
}
       
Describe 'Invoke-PowerShell.when running 32-bit script block from 32-bit PowerShell' {
    $error.Clear()
    if( (Test-PowerShellIs32Bit) )
    {
        $result = Invoke-PowerShell -ScriptBlock { $env:ProgramFiles } -x86
    }
    else
    {
        $command = @"
& "$(Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)"

if( -not (Test-PowerShellIs32Bit) )
{
    throw 'Not in 32-bit PowerShell!'
}
Invoke-PowerShell -ScriptBlock { `$env:ProgramFiles } -x86
"@
        $result = Invoke-PowerShell -Command $command -Encode -x86
    }

    It 'should not write an error' {
        $error.Count | Should Be 0
    }

    It 'should run command under 32-bit PowerShell' {
        ($result -like '*Program Files (x86)*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when running a script' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -ExecutionPolicy RemoteSigned 
    It 'should run the script' {
        $result.Length | Should Be 3
        $result[0] | Should Be ''
        $result[1] | Should Not BeNullOrEmpty
        $result[1].PSVersion | Should Be $PSVersion
        $result[1].CLRVersion | Should Be $CLRVersion
        $result[2] | Should Not BeNullOrEmpty
        $architecture = 'AMD64'
        if( Test-OSIs32Bit )
        {
            $architecture = 'x86'
        }
        $result[2] | Should Be $architecture
    }
}
    
Describe 'Invoke-PowerShell.when running a script with arguments' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -ArgumentList '-Message',"'Hello World'" `
                                -ExecutionPolicy RemoteSigned
    It 'should pass arguments to the script' {
        $result.Length | Should Be 3
        $result[0] | Should Be "'Hello World'"
        $result[1] | Should Not BeNullOrEmpty
        $result[1].PSVersion | Should Be $PSVersion
        $result[1].CLRVersion | Should Be $CLRVersion
    }
}
    
Describe 'Invoke-PowerShell.when running script with -x86 switch' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -x86 `
                                -ExecutionPolicy RemoteSigned 
    It 'should run under 32-bit PowerShell' {
        $result[2] | Should Be 'x86'
    }
}
    
Describe 'Invoke-PowerShell.when running script with v4.0 runtime' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -Runtime 'v4.0' `
                                -ExecutionPolicy RemoteSigned 

    It 'should run under 4.0 CLR' {
        ($result[1].CLRVersion -like '4.0.*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when running script under v2.0 runtime' {
    It '[the test] should make sure .NET 2 is installed' {
        (Test-DotNet -V2) | Should Be $true
    }

    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -Runtime 'v2.0' `
                                -ExecutionPolicy RemoteSigned 
    
    $result | Write-Debug
    It 'should run under .NET 2.0 CLR' {
        ,$result | Should Not BeNullOrEmpty
        ($result[1].CLRVersion -like '2.0.*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when setting execution policy when running a script' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -ExecutionPolicy Restricted `
                                -ErrorAction SilentlyContinue 2>$null
    
    It 'should set the execution policy' {
       $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

$getUsernamePath = Join-Path -Path $PSScriptRoot -ChildPath 'PowerShell\Get-Username.ps1' -Resolve

Describe 'Invoke-PowerShell.when running a script as another user' {
    $Global:Error.Clear()
    $return = 'fubar'
    $result = Invoke-PowerShell -FilePath $getUsernamePath `
                                -ArgumentList '-InputObject',$return `
                                -Credential $CarbonTestUser
    It 'should run the script' {
        $result.Count | Should Be 2
        $result[0] | Should Be $return
        $result[1] | Should Be $CarbonTestUser.UserName
    }

    $result = Invoke-PowerShell -FilePath $getUsernamePath `
                                -ArgumentList '-InputObject',$return `
                                -ExecutionPolicy Restricted `
                                -Credential $CarbonTestUser `
                                -ErrorAction SilentlyContinue
    It 'should use PowerShell parameters' {
        $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

Describe 'Invoke-PowerShell.when running a command as another user' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command '$env:Username' -Credential $CarbonTestUser
    It 'should run the command as the user' {
        $result | Should Be $CarbonTestUser.UserName
    }

    $result = Invoke-PowerShell -Command $getUsernamePath -ExecutionPolicy Restricted -Credential $CarbonTestUser -ErrorAction SilentlyContinue
    It 'should set powershell.exe parameters' {
        $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

Describe 'Invoke-PowerShell.when running a script block as another user' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command { 'fubar' } -Credential $CarbonTestUser -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error | Should Match 'script block as another user'
    }
    It 'should not write anything' {
        $result | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running a command with an argument list' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command 'write-host fubar' -ArgumentList 'snafu' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error | Should Match 'doesn''t support'
    }

    It 'should not run the command' {
        $result | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running non-interactively' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command 'Read-Host ''prompt''' -NonInteractive -ErrorAction SilentlyContinue
    It 'should write an error' {
        Invoke-Command -ScriptBlock {
                                        
                                        $result 
                                        ($Global:Error -join [Environment]::NewLine) 
                                    } |
            Where-Object { $_ -match 'is in NonInteractive mode' } |
            Should Not BeNullOrEmpty
    }
}

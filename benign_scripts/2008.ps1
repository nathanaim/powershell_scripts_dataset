

$script:CimClassName = "PSCore_CimTest1"
$script:CimNamespace = "root/default"
$script:moduleDir = Join-Path -Path $PSScriptRoot -ChildPath assets -AdditionalChildPath CimTest
$script:deleteMof = Join-Path -Path $moduleDir -ChildPath DeleteCimTest.mof
$script:createMof = Join-Path -Path $moduleDir -ChildPath CreateCimTest.mof

$CimCmdletArgs = @{
    Namespace = ${script:CimNamespace}
    ClassName = ${script:CimClassName}
    ErrorAction = "SilentlyContinue"
    }

$script:ItSkipOrPending = @{}

function Test-CimTestClass {
    $null -eq (Get-CimClass @CimCmdletArgs)
}

function Test-CimTestInstance {
    $null -eq (Get-CimInstance @CimCmdletArgs)
}

Describe "Cdxml cmdlets are supported" -Tag CI,RequireAdminOnWindows {
    BeforeAll {
        $skipNotWindows = ! $IsWindows
        if ( $skipNotWindows ) {
            $script:ItSkipOrPending = @{ Skip = $true }
            return
        }

        
        
        
        
        if ( (Get-Command -ErrorAction SilentlyContinue Mofcomp.exe) -eq $null ) {
            $script:ItSkipOrPending = @{ Skip = $true }
            return
        }

        
        
        if ( Test-CimTestClass ) {
            if ( Test-CimTestInstance ) {
                Get-CimInstance @CimCmdletArgs | Remove-CimInstance
            }
            
            
            $result = MofComp.exe $deleteMof
            $script:MofCompReturnCode = $LASTEXITCODE
            if ( $script:MofCompReturnCode -ne 0 ) {
                return
            }
        }

        
        
        
        $testMof = Get-Content -Path ${script:createmof} -Raw
        $currentTimeZone = [System.TimeZoneInfo]::Local

        
        
        
        $offsetMinutes = ($currentTimeZone.GetUtcOffset([datetime]::new(2008, 01, 01, 0, 0, 0))).TotalMinutes
        $UTCOffset = "{0:+000;-000}" -f $offsetMinutes
        $testMof = $testMof.Replace("<UTCOffSet>", $UTCOffset)
        Set-Content -Path $testDrive\testmof.mof -Value $testMof
        $result = MofComp.exe $testDrive\testmof.mof
        $script:MofCompReturnCode = $LASTEXITCODE
        if ( $script:MofCompReturnCode -ne 0 ) {
            return
        }

        
        if ( Get-Module CimTest ) {
            Remove-Module -force CimTest
        }
        Import-Module -force ${script:ModuleDir}
    }

    AfterAll {
        if ( $skipNotWindows ) {
            return
        }
        if ( get-module CimTest ) {
            Remove-Module CimTest -Force
        }
        $null = MofComp.exe $deleteMof
        if ( $LASTEXITCODE -ne 0 ) {
            Write-Warning "Could not remove PSCore_CimTest class"
        }
    }

    BeforeEach {
        If ( $script:MofCompReturnCode -ne 0 ) {
            throw "MofComp.exe failed with exit code $MofCompReturnCode"
        }
    }

    Context "Module level tests" {
        It "The CimTest module should have been loaded" @ItSkipOrPending {
            $result = Get-Module CimTest
            $result.ModuleBase | should -Be ${script:ModuleDir}
        }

        It "The CimTest module should have the proper cmdlets" @ItSkipOrPending {
            $result = Get-Command -Module CimTest
            $result.Count | Should -Be 4
            ($result.Name | sort-object ) -join "," | Should -Be "Get-CimTest,New-CimTest,Remove-CimTest,Set-CimTest"
        }
    }

    Context "Get-CimTest cmdlet" {
        It "The Get-CimTest cmdlet should return 4 objects" @ItSkipOrPending {
            $result = Get-CimTest
            $result.Count | should -Be 4
            ($result.id |sort-object) -join ","  | should -Be "1,2,3,4"
        }

        It "The Get-CimTest cmdlet should retrieve an object via id" @ItSkipOrPending {
            $result = Get-CimTest -id 1
            @($result).Count | should -Be 1
            $result.field1 | Should -Be "instance 1"
        }

        It "The Get-CimTest cmdlet should retrieve an object by piped id" @ItSkipOrPending {
            $result = 1,2,4 | foreach-object { [pscustomobject]@{ id = $_ } } | Get-CimTest
            @($result).Count | should -Be 3
            ( $result.id | sort-object ) -join "," | Should -Be "1,2,4"
        }

        It "The Get-CimTest cmdlet should retrieve an object by datetime" @ItSkipOrPending {
            $result = Get-CimTest -DateTime ([datetime]::new(2008,01,01,0,0,0))
            @($result).Count | Should -Be 1
            $result.field1 | Should -Be "instance 1"
        }

        It "The Get-CimTest cmdlet should return the proper error if the instance does not exist" @ItSkipOrPending {
            { Get-CimTest -ErrorAction Stop -id "ThisIdDoesNotExist" } | Should -Throw -ErrorId "CmdletizationQuery_NotFound_Id,Get-CimTest"
        }

        It "The Get-CimTest cmdlet should work as a job" @ItSkipOrPending {
            try {
                $job = Get-CimTest -AsJob
                $result = $null
                
                
                
                $null = Wait-Job -Job $job -timeout 10
                $result = $job | Receive-Job
                $result.Count | should -Be 4
                ( $result.id | sort-object ) -join "," | Should -Be "1,2,3,4"
            }
            finally {
                if ( $job ) {
                    $job | Remove-Job -force
                }
            }
        }

        It "Should be possible to invoke a method on an object returned by Get-CimTest" @ItSkipOrPending {
            $result = Get-CimTest | Select-Object -first 1
            $result.GetCimSessionInstanceId() | Should -BeOfType [guid]
        }
    }

    Context "Remove-CimTest cmdlet" {
        BeforeEach {
            Get-CimTest | Remove-CimTest
            1..4 | Foreach-Object { New-CimInstance -namespace root/default -class PSCore_Test1 -property @{
                id = "$_"
                field1 = "field $_"
                field2 = 10 * $_
                }
            }
        }

        It "The Remote-CimTest cmdlet should remove objects by id" @ItSkipOrPending {
            Remove-CimTest -id 1
            $result = Get-CimTest
            $result.Count | should -Be 3
            ($result.id |sort-object) -join ","  | should -Be "2,3,4"
        }

        It "The Remove-CimTest cmdlet should remove piped objects" @ItSkipOrPending {
            Get-CimTest -id 2 | Remove-CimTest
            $result  = Get-CimTest
            @($result).Count | should -Be 3
            ($result.id |sort-object) -join ","  | should -Be "1,3,4"
        }

        It "The Remove-CimTest cmdlet should work as a job" @ItSkipOrPending {
            try {
                $job = Get-CimTest -id 3 | Remove-CimTest -asjob
                $result = $null
                
                
                
                $null = Wait-Job -Job $job -Timeout 10
                $result  = Get-CimTest
                @($result).Count | should -Be 3
                ($result.id |sort-object) -join ","  | should -Be "1,2,4"
            }
            finally {
                if ( $job ) {
                    $job | Remove-Job -force
                }
            }
        }
    }

    Context "New-CimTest operations" {
        It "Should create a new instance" @ItSkipOrPending {
            $instanceArgs = @{
                id = "telephone"
                field1 = "television"
                field2 = 0
            }
            New-CimTest @instanceArgs
            $result = Get-CimInstance -namespace root/default -class PSCore_Test1 | Where-Object {$_.id -eq "telephone"}
            $result.field2 | should -Be 0
            $result.field1 | Should -Be $instanceArgs.field1
        }

        It "Should return the proper error if called with an improper value" @ItSkipOrPending {
            $instanceArgs = @{
                Id = "error validation"
                field1 = "a string"
                field2 = "a bad string" 
            }
            { New-CimTest @instanceArgs } | Should -Throw -ErrorId "ParameterArgumentTransformationError,New-CimTest"
            
            Get-CimTest -id $instanceArgs.Id -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }

        It "Should support -whatif" @ItSkipOrPending {
            $instanceArgs = @{
                Id = "1000"
                field1 = "a string"
                field2 = 111
                Whatif = $true
            }
            New-CimTest @instanceArgs
            Get-CimTest -id $instanceArgs.Id -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }

    Context "Set-CimTest operations" {
        It "Should set properties on an instance" @ItSkipOrPending {
            $instanceArgs = @{
                id = "updateTest1"
                field1 = "updatevalue"
                field2 = 100
            }
            $newValues = @{
                id = "updateTest1"
                field2 = 22
                field1 = "newvalue"
            }
            New-CimTest @instanceArgs
            $result = Get-CimTest -id $instanceArgs.id
            $result.field2 | should -Be $instanceArgs.field2
            $result.field1 | Should -Be $instanceArgs.field1
            Set-CimTest @newValues
            $result = Get-CimTest -id $newValues.id
            $result.field1 | Should -Be $newValues.field1
            $result.field2 | should -Be $newValues.field2
        }

        It "Should set properties on an instance via pipeline" @ItSkipOrPending {
            $instanceArgs = @{
                id = "updateTest2"
                field1 = "updatevalue"
                field2 = 100
            }
            New-CimTest @instanceArgs
            $result = Get-CimTest -id $instanceArgs.id
            $result.field2 | should -Be $instanceArgs.field2
            $result.field1 | Should -Be $instanceArgs.field1
            $result.field1 = "yet another value"
            $result.field2 = 33
            $result | Set-CimTest
            $result = Get-CimTest -id $instanceArgs.id
            $result.field1 | Should -Be "yet another value"
            $result.field2 | should -Be 33
        }
    }

}

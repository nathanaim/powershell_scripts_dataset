


Describe 'Get-Error tests' -Tag CI {
    BeforeAll {
        $skipTest = -not $EnabledExperimentalFeatures.Contains('Microsoft.PowerShell.Utility.PSGetError')
        if ($skipTest) {
            Write-Verbose "Test Suite Skipped. The test suite requires the experimental feature 'Microsoft.PowerShell.Utility.PSGetError' to be enabled." -Verbose
            $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
            $PSDefaultParameterValues["it:skip"] = $true
        }
    }

    AfterAll {
        if ($skipTest) {
            $global:PSDefaultParameterValues = $originalDefaultParameterValues
        }
    }

    It 'Get-Error resolves $Error[0] and includes InnerException' {
        try {
            1/0
        }
        catch {
        }

        $out = Get-Error | Out-String
        $out | Should -BeLikeExactly '*InnerException*'
    }

    It 'Get-Error -Newest `<count>` works: <scenario>' -TestCases @(
        @{ scenario = 'less than total'; count = 1; paramname = 'Newest' }
        @{ scenario = 'equal to total'; count = 2; paramname = 'Last' }
        @{ scenario = 'greater than total'; count = 9999; paramname = 'Newest' }
    ){
        param ($count, $paramname)

        try {
            1/0
        }
        catch {
        }

        try {
            get-item (new-guid) -ErrorAction SilentlyContinue
        }
        catch {
        }

        $params = @{ $paramname = $count }

        $out = Get-Error @params

        $expected = $count
        if ($count -eq 9999) {
            $expected = $error.Count
        }

        $out.Count | Should -Be $expected
    }

    It 'Get-Error -Newest with invalid value `<value>` should fail' -TestCases @(
        @{ value = 0 }
        @{ value = -2 }
    ){
        param($value)

        { Get-Error -Newest $value } | Should -Throw -ErrorId 'ParameterArgumentValidationError,Microsoft.PowerShell.Commands.GetErrorCommand'
    }

    It 'Get-Error will accept pipeline input' {
        try {
            1/0
        }
        catch {
        }

        $out = $error[0] | Get-Error | Out-String
        $out | Should -BeLikeExactly '*-2146233087*'
    }

    It 'Get-Error will handle Exceptions' {
        try {
            Invoke-Expression '1/d'
        }
        catch {
        }

        $out = Get-Error | Out-String
        $out | Should -BeLikeExactly '*ExpectedValueExpression*'
        $out | Should -BeLikeExactly '*UnexpectedToken*'
    }
}

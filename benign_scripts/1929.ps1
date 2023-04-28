


Import-Module HelpersCommon

Describe "Set-Date for admin" -Tag @('CI', 'RequireAdminOnWindows', 'RequireSudoOnUnix') {
    
    It "Set-Date should be able to set the date in an elevated context" -Skip:(Test-IsVstsLinux) {
        { Get-Date | Set-Date } | Should -Not -Throw
    }

    
    It "Set-Date should be able to set the date with -Date parameter" -Skip:(Test-IsVstsLinux) {
        $target = Get-Date
        $expected = $target
        Set-Date -Date $target | Should -Be $expected
    }
}

Describe "Set-Date" -Tag 'CI' {
    It "Set-Date should produce an error in a non-elevated context" {
        { Get-Date | Set-Date } | Should -Throw -ErrorId "System.ComponentModel.Win32Exception,Microsoft.PowerShell.Commands.SetDateCommand"
    }
}

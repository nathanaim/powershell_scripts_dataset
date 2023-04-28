

Describe "Get-EventLog cmdlet tests" -Tags @('CI', 'RequireAdminOnWindows') {

    BeforeAll {
        $defaultParamValues = $PSdefaultParameterValues.Clone()
        $PSDefaultParameterValues["it:skip"] = !$IsWindows -or $IsCoreCLR
    }

    AfterAll {
        $global:PSDefaultParameterValues = $defaultParamValues
    }

    
    It "should return an array of eventlogs objects when called with -AsString parameter" -Pending:($True) {
      { $result=Get-EventLog -AsString -ErrorAction Stop } | Should -Not -Throw
      $result                                              | Should -Not -BeNullOrEmpty
      ,$result                                             | Should -BeOfType "System.Array"
      $result                                              | Should -BeExactly "Application"
      $result.Count                                        | Should -BeGreaterThan 3
    }
    It "should return a list of eventlog objects when called with -List parameter" -Pending:($True) {
      { $result=Get-EventLog -List -ErrorAction Stop }      | Should -Not -Throw
      $result                                               | Should -Not -BeNullOrEmpty
      ,$result                                              | Should -BeOfType "System.Array"
      {$logs=$result | Select-Object -ExpandProperty Log}   | Should -Not -Throw
      $logs                                                 | Should -BeExactly "System"
      $logs.Count                                           | Should -BeGreaterThan 3
    }
    It "should be able to Get-EventLog -LogName Application -Newest 100" -Pending:($True) {
      { $result=get-eventlog -LogName Application -Newest 100 -ErrorAction Stop } | Should -Not -Throw
      $result                                                                     | Should -Not -BeNullOrEmpty
      $result.Length                                                              | Should -BeLessThan 100
      $result[0]                                                                  | Should -BeOfType "EventLogEntry"
    }
    It "should throw 'AmbiguousParameterSetException' when called with both -LogName and -List parameters" -Pending:($True) {
      { Get-EventLog -LogName System -List -ErrorAction Stop } | Should -Throw -ErrorId "AmbiguousParameterSet,Microsoft.PowerShell.Commands.GetEventLogCommand"
    }
    It "should be able to Get-EventLog -LogName * with multiple matches" -Pending:($True) {
      { $result=get-eventlog -LogName *  -ErrorAction Stop }  | Should -Not -Throw
      $result                                                 | Should -Not -BeNullOrEmpty
      $result                                                 | Should -BeExactly "Security"
      $result.Count                                           | Should -BeGreaterThan 3
    }
    It "should throw 'InvalidOperationException' when asked to get a log that does not exist" -Pending:($True) {
      { Get-EventLog  -LogName MissingTestLog -ErrorAction Stop } | Should -Throw -ErrorId "System.InvalidOperationException,Microsoft.PowerShell.Commands.GetEventLogCommand"
    }
}

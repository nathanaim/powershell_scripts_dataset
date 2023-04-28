


Describe "Tests Debugger GetCallStack() on runspaces when attached to a WinRM host process" -Tags "CI" {

    It -skip "Disabled test because it is fragile and does not consistently succeed on test VMs" { }
    return

    try
    {
        
        $wc = [System.Management.Automation.Runspaces.WSManConnectionInfo]::new()
        $rs = [runspacefactory]::CreateRunspace($host, $wc)
        $rs.Open()

        
        [powershell] $ps = [powershell]::Create()
        $ps.Runspace = $rs
        $result = $ps.AddScript('$pid').Invoke()
        It "Verifies the WinRM host process Id was found" {
            $result | Should -Not -BeNullOrEmpty
            ($result.Count -eq 1) | Should -BeTrue
        }
        [int]$winRMHostProcId = $result[0]

        
        $ps.Commands.Clear()
        $ps.AddScript('"Hello"; Wait-Debugger; "Goodbye"').BeginInvoke()

        
        Enter-PSHostProcess -Id $winRMHostProcId

        
        $hostRS = Get-Runspace -Name PSAttachRunspace
        It "Verifies that the attached-to host runspace was found" {
            $hostRS | Should -Not -BeNullOrEmpty
            ($hostRS.RunspaceStateInfo.State -eq 'Opened') | Should -BeTrue
        }

        
        $count = 0
        while (($hostRS.RunspaceAvailability -ne 'Available') -and ($count++ -lt 60))
        {
            Start-Sleep -Milliseconds 500
        }
        It "Verifies that the attached-to host runspace is available" {
            ($hostRS.RunspaceAvailability -eq 'Available') | Should -BeTrue
        }

        
        $script = @'
            $rs = Get-Runspace -Id 1
            if ($null -eq $rs) { throw 'Runspace not found' }
            return $rs.Debugger.GetCallStack()
'@
        [powershell]$psHost = [powershell]::Create()
        $psHost.Runspace = $hostRS
        $psHost.AddScript($script)
        $stack = $psHost.Invoke()

        
        Exit-PSHostProcess

        It "Verifies a call stack was returned from the attached-to host." {
            $stack | Should -Not -BeNullOrEmpty
            ($stack.Count -gt 0) | Should -BeTrue
        }
    }
    finally
    {
        
        if ($host.IsRunspacePushed) { $host.PopRunspace() }

        if ($null -ne $psHost) { $psHost.Dispose() }
        if ($null -ne $hostRS) { $hostRS.Dispose() }
        if ($null -ne $ps) { $ps.Dispose() }
        if ($null -ne $rs) { $rs.Dispose() }
    }
}

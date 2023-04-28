
function Enable-CFirewallStatefulFtp
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Assert-CFirewallConfigurable) )
    {
        return
    }
    
    Invoke-ConsoleCommand -Target 'firewall' -Action 'enable stateful FTP' -ScriptBlock {
        netsh advfirewall set global StatefulFtp enable
    }
}


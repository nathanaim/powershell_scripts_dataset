
function Resolve-CNetPath
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Warning ('Resolve-CNetPath is obsolete and will be removed in a future major version of Carbon. Do not use.')
    
    $netCmd = Get-Command -CommandType Application -Name net.exe* |
                Where-Object { $_.Name -eq 'net.exe' }
    if( $netCmd )
    {
        return $netCmd.Definition
    }
    
    $netPath = Join-Path $env:WINDIR system32\net.exe
    if( (Test-Path -Path $netPath -PathType Leaf) )
    {
        return $netPath
    }
    
    Write-Error 'net.exe command not found.'
    return $null
}

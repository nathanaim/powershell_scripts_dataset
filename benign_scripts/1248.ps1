
function ConvertTo-CBase64
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]
        
        $Value,
        
        [Text.Encoding]
        
        $Encoding = ([Text.Encoding]::Unicode)
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState    
    }

    process
    {
        $Value | ForEach-Object {
            if( $_ -eq $null )
            {
                return $null
            }
            
            $bytes = $Encoding.GetBytes($_)
            [Convert]::ToBase64String($bytes)
        }
    }
}

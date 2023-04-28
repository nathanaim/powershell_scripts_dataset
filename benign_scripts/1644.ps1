

function Get-ChromeExtension {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    Get-ChildItem "\\$ComputerName\c$\users\*\appdata\local\Google\Chrome\User Data\Default\Extensions\*\*\manifest.json" -ErrorAction SilentlyContinue | % {
        $path = $_.FullName
        $_.FullName -match 'users\\(.*?)\\appdata' | Out-Null
        Get-Content $_.FullName -Raw | ConvertFrom-Json | select @{n='ComputerName';e={$ComputerName}}, @{n='User';e={$Matches[1]}}, Name, Version, @{n='Path';e={$path}}
    }
}

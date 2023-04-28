


Import-Module $PSScriptRoot/SystemD/SystemD.psm1


Write-host -Foreground Blue "Get recent SystemD journal messages"
Get-SystemDJournal -args "-xe" |Out-Host


Write-host -Foreground Blue "Get recent SystemD journal messages for services and return Unit, Message"
Get-SystemDJournal -args "-xe" | Where-Object {$_._SYSTEMD_UNIT -like "*.service"} | Format-Table _SYSTEMD_UNIT, MESSAGE | Select-Object -first 10 | Out-Host

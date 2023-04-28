
function Update-Plugin {
    
    [PoshBot.BotCommand(
        Aliases = ('up', 'updateplugin'),
        Permissions = 'manage-plugins'
    )]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Mandatory, Position = 0)]
        [string[]]$Name,

        [parameter(Position = 1)]
        [ValidateScript({
            if ($_ -as [Version]) {
                $true
            } else {
                throw 'Version parameter must be a valid semantic version string (1.2.3)'
            }
        })]
        [string]$Version,

        [switch]$RemoveOldVersions
    )

    foreach ($item in $Name) {
        if ($item -eq 'Builtin') {
            New-PoshBotCardResponse -Type Warning -Text 'The builtin plugin cannot be updated as it is shipped with PoshBot' -Title 'Not gonna do it'
            continue
        }

        
        $existingPlugin = $Bot.PluginManager.Plugins[$item]
        if (-not $existingPlugin) {
            New-PoshBotCardResponse -Type Warning -Text "Plugin [$item] is not installed. The plugin must be installed before you can update it."
            return
        } else {
            $existingPluginVersions = $existingPlugin.Keys | Sort-Object -Descending

            try {
                
                $params = @{
                    Name = $item
                    Force = $true
                    Confirm = $false
                }
                if ($PSBoundParameters.ContainsKey('Version')) {
                    $params.RequiredVersion = $Version
                }

                
                if ($PSBoundParameters.ContainsKey('Version')) {
                    
                    if (-not (Get-Module -Name $item -ListAvailable | Where-Object {$_.Version -eq $Version})) {
                        Update-module @params
                    }
                    $newMod = Get-Module -Name $item -ListAvailable | Where-Object {$_.Version -eq $Version}
                } else {
                    Update-module @params
                    $newMod = @(Get-Module -Name $item -ListAvailable | Sort-Object -Property Version -Descending)[0]
                }

                
                if ($existingPluginVersions -notcontains $newMod.Version) {
                    $Bot.PluginManager.InstallPlugin($newMod.Path, $true)

                    $resp = Get-Plugin -Bot $Bot -Name $item -Version $newMod.Version
                    if (-not ($resp | Get-Member -Name 'Title' -MemberType NoteProperty)) {
                        $resp | Add-Member -Name 'Title' -MemberType NoteProperty -Value $null
                    }
                    $resp.Title = "Plugin [$item] updated to version [$($newMod.Version)]"

                    
                    if ($RemoveOldVersions) {
                        $existingPlugin = $Bot.PluginManager.Plugins[$item]
                        $oldKeys = $existingPlugin.Keys | Where-Object {$_ -ne $newMod.Version}
                        $oldKeys | ForEach-Object {
                            $Bot.PluginManager.RemovePlugin($item, $_)
                        }
                    }

                    $resp
                }
            } catch {
                New-PoshBotCardResponse -Type Error -Text $_.Exception.Message -Title 'Rut row' -ThumbnailUrl $thumb.rutrow
            }
        }
    }
}

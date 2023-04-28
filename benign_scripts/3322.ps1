
function Find-Plugin {
    
    [PoshBot.BotCommand(Permissions = 'manage-plugins')]
    [cmdletbinding()]
    param(
        [parameter(Mandatory)]
        $Bot,

        [parameter(Position = 0)]
        [string]$Name,

        [parameter(Position = 1)]
        [string]$Repository = 'PSGallery'
    )

    $params = @{
        Repository = $Repository
        Tag = 'poshbot'
    }
    if (-not [string]::IsNullOrEmpty($Name)) {
        $params.Name = "*$Name*"
    } else {
        $params.Filter = 'poshbot'
    }
    $plugins = @(Find-Module @params | Where-Object {$_.Name -ne 'Poshbot'} | Sort-Object -Property Name)

    if ($plugins) {
        if ($plugins.Count -eq 1) {
            $details = $plugins | Select-Object -Property 'Name', 'Description', 'Version', 'Author', 'CompanyName', 'Copyright', 'PublishedDate', 'ProjectUri', 'Tags'
            $cardParams = @{
                Type = 'Normal'
                Title = "Found [$($details.Name)] on [$Repository]"
                Text = ($details | Format-List -Property * | Out-String)
            }
            if (-not [string]::IsNullOrEmpty($details.IconUri)) {
                $cardParams.ThumbnailUrl = $details.IconUri
            }
            if (-not [string]::IsNullOrEmpty($details.ProjectUri)) {
                $cardParams.LinkUrl = $details.ProjectUri
            }
            New-PoshBotCardResponse @cardParams
        } else {
            New-PoshBotCardResponse -Type Normal -Title "Available PoshBot plugins on [$Repository]" -Text ($plugins | Format-Table -Property Name, Version, Description -AutoSize | Out-String)
        }
    } else {
        $notFoundParams = @{
            Type = 'Warning'
            Title = 'Terrible news'
            ThumbnailUrl = 'http://p1cdn05.thewrap.com/images/2015/06/don-draper-shrug.jpg'
        }
        if (-not [string]::IsNullOrEmpty($Name)) {
            $notFoundParams.Text = "No PoshBot plugins matching [$Name] where found in repository [$Repository]"
        } else {
            $notFoundParams.Text = "No PoshBot plugins where found in repository [$Repository]"
        }
        New-PoshBotCardResponse @notFoundParams
    }
}

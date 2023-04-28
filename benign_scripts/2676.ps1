param(
    [switch]$Force
)

. $PSScriptRoot/shared.ps1

$templateConfigurationsList = '/Lists/Templates'
$baseModulesLibrary = 'BaseModules'
$subModulesLibrary = 'AppsModules'
$timerIntervalMinutes = 30;

function GetUniqueUrlFromName($title) {
    Connect -Url $tenantAdminUrl
    $cleanName = $title -replace '[^a-z0-9]'
    if ([String]::IsNullOrWhiteSpace($cleanName)) {
        $cleanName = "team"
    }
    $url = "$tenantUrl/$managedPath/$cleanName"
    $doCheck = $true
    while ($doCheck) {
        Get-PnPTenantSite -Url $url -ErrorAction SilentlyContinue >$null 2>&1
        if ($? -eq $true) {
            $url += '1'
        }
        else {
            $doCheck = $false
        }
    }
    return $url
}

function EnsureSite {
    Param(
        [string]$siteEntryId,
        [string]$title,
        [string]$siteUrl,
        [string]$description = "",
        [string]$siteCollectionAdmin,
        [Microsoft.SharePoint.Client.User]$owner,
        [String[]]$ownerAddresses,
        [String[]]$members,
        [String[]]$visitors
    )

    
    Connect -Url $tenantAdminUrl
    $site = Get-PnPTenantSite -Url $siteUrl -ErrorAction SilentlyContinue
    if ( $? -eq $false) {
        Write-Output -InputObject "Site at $siteUrl does not exist - let's create it"
        $site = New-PnPTenantSite -Title $title -Url $siteUrl -Owner $siteCollectionAdmin -TimeZone 3 -Description $description -Lcid 1033 -Template "STS
        if ($? -eq $false) {
            
            $mailHeadBody = GetMailContent -email $owner.Email -mailFile "fail"
            Write-Output -InputObject "Sending fail mail to $ownerAddresses"
            Send-PnPMail -To $ownerAddresses -Subject $mailHeadBody[0] -Body ($mailHeadBody[1] -f $siteUrl)
            Write-Error -Message "Something happened"
            UpdateStatus -id $siteEntryId -status 'Failed'
            return;
        }
    }
    elseif ($site.Status -ne "Active") {
        Write-Output -InputObject "Site at $siteUrl already exist"
        while ($true) {
            
            $site = Get-PnPTenantSite -Url $siteUrl
            if ( $site.Status -eq "Active" ) {
                break;
            }
            Write-Output -InputObject "Site not ready"
            Start-Sleep -s 20
        }
    }
}

function EnsureSecurityGroups([string]$siteUrl, [string]$title, [string[]]$owners, [string[]]$members, [string[]]$visitors, [string]$siteCollectionAdmin) {
    Connect -Url $siteUrl

    $visitorsGroup = Get-PnPGroup -AssociatedVisitorGroup -ErrorAction SilentlyContinue
    if ( $? -eq $false) {
        Write-Output -InputObject "Creating visitors group"
        $visitorsGroup = New-PnPGroup -Title "$title Visitors" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $visitorsGroup -SetAssociatedGroup Visitors
    }

    $membersGroup = Get-PnPGroup -AssociatedMemberGroup -ErrorAction SilentlyContinue
    if ( $? -eq $false) {
        Write-Output -InputObject "Creating members group"
        $membersGroup = New-PnPGroup -Title "$title Members" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $membersGroup -SetAssociatedGroup Members
    }

    $ownersGroup = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue
    if ( $? -eq $false) {
        Write-Output -InputObject "Creating owners group"
        $ownersGroup = New-PnPGroup -Title "$title Owners" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $ownersGroup -SetAssociatedGroup Owners
    }

    if ($owners -ne $null) {        
        $existingOwners = @($ownersGroup.Users | Select-Object -ExpandProperty LoginName)
        foreach ($login in $owners) {            
            if (-not $existingOwners.Contains($login)) {
                Write-Output -InputObject "`tAdding owner: $login"
                Add-PnPUserToGroup -Identity $ownersGroup -LoginName $login
            }
        }
    }

    if ($members -ne $null) {
        $existingMembers = @($membersGroup.Users | Select-Object -ExpandProperty LoginName)
        foreach ($login in $members) {
            if (-not $existingOwners.Contains($login)) {
                Write-Output -InputObject "`tAdding member: $login"
                Add-PnPUserToGroup -Identity $membersGroup -LoginName $login
            }
        }
    }

    if ($visitors -ne $null) {
        $existingVisitors = @($visitorsGroup.Users | Select-Object -ExpandProperty LoginName)
        foreach ($login in $visitors) {
            if (-not $existingOwners.Contains($login)) {
                Write-Output -InputObject "`tAdding visitor: $login"
                Add-PnPUserToGroup -Identity $visitorsGroup -LoginName $login
            }
        }
    }
}

function ApplyTemplate([string]$siteUrl, [string]$templateUrl, [string]$templateName) {
    Connect -Url $siteUrl

    $appliedTemplates = Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey
    if ((-not $appliedTemplates.Contains("|$templateName|") -or $Force)) {
        Write-Output -InputObject "`tApplying template $templateName to $siteUrl"
        Apply-PnPProvisioningTemplate -Path $templateUrl
        if ($? -eq $true) {
            $appliedTemplates = "$appliedTemplates|$templateName|"
            Set-PnPPropertyBagValue -Key $propBagTemplateInfoStampKey -Value $appliedTemplates
        }
    }
    else {
        Write-Output -InputObject "`tTemplate $templateName already applied to $siteUrl"
    }
}

function SetSiteUrl($siteItem, $siteUrl, $title) {
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Write-Output -InputObject "`tSetting site URL to $siteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $siteItem["ID"] -Values @{"$($columnPrefix)SiteURL" = "$siteUrl, $title"} -ErrorAction SilentlyContinue >$null 2>&1
}

function UpdateStatus($id, $status) {
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $id -Values @{"$($columnPrefix)SiteStatus" = $status} -ErrorAction SilentlyContinue >$null 2>&1
}

function SendReadyEmail() {
    Param(
        [string]$siteUrl,
        [string]$toEmail,
        [String[]]$ccEmails,
        [string]$title
    )
    Connect -Url $siteUrl
    if ( -not [string]::IsNullOrWhiteSpace($toEmail) ) {
        $mailHeadBody = GetMailContent -email $toEmail -mailFile "welcome"

        Write-Output -InputObject "Sending ready mail to $toEmail and $ccEmails"
        Send-PnPMail -To $toEmail -Cc $ccEmails -Subject ($mailHeadBody[0] -f $title) -Body ($mailHeadBody[1] -f $title, $siteUrl)
    }
}


function Apply-TemplateConfigurations($siteUrl, $siteItem, $templateConfigurationItems, $baseModuleItems, $subModuleItems) {
    Connect -Url $siteUrl

    $templateConfig = $siteItem["$($columnPrefix)TemplateConfig"]
    $subModules = $siteItem["$($columnPrefix)SubModules"]

    if ($templateConfig -ne $null) {
        $chosenTemplateConfig = $templateConfigurationItems | Where-Object -Property Id -eq $templateConfig.LookupId

        $hasTemplate = Get-PnPPropertyBag -Key $propBagTemplateNameStampKey
        if (-not $hasTemplate) {
            
            $allGood = $true
            if ($chosenTemplateConfig -ne $null) {
                $chosenBaseTemplate = $chosenTemplateConfig["$($columnPrefix)BaseModule"]
                $chosenSubModules = $chosenTemplateConfig["$($columnPrefix)SubModules"]

                if ($chosenBaseTemplate -ne $null) {
                    $pnpTemplate = $baseModuleItems | Where-Object -Property Id -eq $chosenBaseTemplate.LookupId
                    $pnpUrl = $tenantUrl + $pnpTemplate["FileRef"]
                    $templateName = $pnpTemplate["FileLeafRef"]
                    ApplyTemplate -siteUrl $siteUrl -templateUrl $pnpUrl -templateName $templateName
                    
                    $appliedTemplates = Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey
                    if (-not $appliedTemplates.Contains("|$templateName|")) {
                        $allGood = $false
                    }
                }
                if ($chosenSubModules -ne $null) {
                    foreach ($module in $chosenSubModules) {
                        $pnpTemplate = $subModuleItems | Where-Object -Property Id -eq $module.LookupId
                        $pnpUrl = $tenantUrl + $pnpTemplate["FileRef"]
                        $templateName = $pnpTemplate["FileLeafRef"]
                        ApplyTemplate -siteUrl $siteUrl -templateUrl $pnpUrl -templateName $templateName
                        $appliedTemplates = Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey
                        if (-not $appliedTemplates.Contains("|$templateName|")) {
                            $allGood = $false
                        }
                    }
                }
            }
            if ($allGood) {
                Write-Output -InputObject "`tTemplate $($chosenTemplateConfig["Title"]) applied"
                Set-PnPPropertyBagValue -Key $propBagTemplateNameStampKey -Value $chosenTemplateConfig["Title"]
            }
        }
    }

    foreach ($module in $subModules) {
        $pnpTemplate = $subModuleItems | Where-Object -Property Id -eq $module.LookupId
        $pnpUrl = $tenantUrl + $pnpTemplate["FileRef"]
        ApplyTemplate -siteUrl $siteUrl -templateUrl $pnpUrl -templateName $pnpTemplate["FileLeafRef"]
    }

    
    Connect -Url $siteUrl
    $appliedTemplates = (Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey).Split('|') | Where-Object -FilterScript {$_} 
    $ids = $appliedTemplates | Foreach-Object -Process {
        $name = $_
        $subModuleItems | Where-Object -FilterScript {$_["FileLeafRef"] -eq $name} | Select-Object -ExpandProperty Id
    }
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $siteItem["ID"] -Values @{"$($columnPrefix)SubModules" = $ids} -ErrorAction SilentlyContinue >$null 2>&1
    
}

function SyncMetadata($siteUrl, $title, $description) {
    Connect -Url $siteUrl
    $web = Get-PnPWeb -Includes Description
    if ($web.Title -ne $title -or $web.Description -ne $description) {
        Write-Output -InputObject "`tSync title/description to $siteUrl"
        Set-PnPWeb -Title $title -Description $description
    }
}

function GetRecentlyUpdatedItems($IntervalMinutes) {
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    $date = [DateTime]::UtcNow.AddMinutes( - $IntervalMinutes).ToString("yyyy\-MM\-ddTHH\:mm\:ssZ")
    $recentlyUpdatedCaml = @"
<View>
    <Query>
        <Where>
            <Gt>
                <FieldRef Name="Modified" />
                <Value IncludeTimeValue="True" Type="DateTime" StorageTZ="TRUE">$date</Value>
            </Gt>
        </Where>
        <OrderBy>
            <FieldRef Name="Modified" Ascending="False" />
        </OrderBy>
    </Query>
    <ViewFields>
        <FieldRef Name="ID" />
    </ViewFields>
</View>
"@
    if ($Force) {
        return @(Get-PnPListItem -List $siteDirectoryList)    
    }
    else {
        return @(Get-PnPListItem -List $siteDirectoryList -Query $recentlyUpdatedCaml)
    }    
}

Write-Output -InputObject @"
  ___  ___      ______               _     _
  |  \/  |      | ___ \             (_)   (_)
  | .  . |_ __  | |_/ / __ _____   ___ ___ _  ___  _ __
  | |\/| | '__| |  __/ '__/ _ \ \ / / / __| |/ _ \| '_ \
  | |  | | |_   | |  | | | (_) \ V /| \__ \ | (_) | | | |
  \_|  |_/_(_)  \_|  |_|  \___/ \_/ |_|___/_|\___/|_| |_|
                                            by Puzzlepart
  Code by: @mikaelsvenson / @tarjeieo

"@

$variablesSet = CheckEnvironmentalVariables
if ($variablesSet -eq $false) {    
    Write-Output -InputObject "Missing one of the following environmental variables: TenantURL, PrimarySiteCollectionOwnerEmail, SiteDirectoryUrl, AppId, AppSecret"
    exit
}

Connect -Url "$tenantURL$siteDirectorySiteUrl"
$templateConfigurationItems = @(Get-PnPListItem -List $templateConfigurationsList)
$baseModuleItems = @(Get-PnPListItem -List $baseModulesLibrary)
$subModuleItems = @(Get-PnPListItem -List $subModulesLibrary)
$siteDirectoryItems = GetRecentlyUpdatedItems -Interval $timerIntervalMinutes

if (!$siteDirectoryItems -or ($siteDirectoryItems -ne $null -and (0 -eq $siteDirectoryItems.Count))) {
    Write-Output -InputObject "No site requests detected last $timerIntervalMinutes minutes"
}

foreach ($siteItem in $siteDirectoryItems) {
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    $siteItem = Get-PnPListItem -List $siteDirectoryList -Id $siteItem.ID 

    $editor = $siteItem["Editor"][0].LookUpValue 
    $orderedByUser = $siteItem["Author"][0]

    $title = $siteItem["Title"]
    $description = $siteItem["$($columnPrefix)ProjectDescription"]
    $ownerEmailAddresses = @(@($siteItem["$($columnPrefix)SiteOwners"]) | Where-Object -FilterScript {-not [String]::IsNullOrEmpty($_.Email)} | Select-Object -ExpandProperty Email)
    $siteStatus = $siteItem["$($columnPrefix)SiteStatus"]

    $ownerEmailAddresses = $ownerEmailAddresses | Select-Object -Unique | Sort-Object

    $businessOwnerEmailAddress = @($siteItem["$($columnPrefix)BusinessOwner"] | Where-Object -FilterScript {-not [String]::IsNullOrEmpty($_.Email)} | Select-Object -ExpandProperty Email)

    $owners = @($siteItem["$($columnPrefix)SiteOwners"]) | Select-Object -ExpandProperty LookupId
    $owners = @($owners | Foreach-Object -Process { GetLoginName -lookupId $_ })
    $members = @($siteItem["$($columnPrefix)SiteMembers"]) | Select-Object -ExpandProperty LookupId
    $members = @($members | Foreach-Object -Process { GetLoginName -lookupId $_ })
    $visitors = @($siteItem["$($columnPrefix)SiteVisitors"]) | Select-Object -ExpandProperty LookupId
    $visitors = @($visitors | Foreach-Object -Process { GetLoginName -lookupId $_ })

    $ownerAccount = GetLoginName -lookupId $siteItem["$($columnPrefix)BusinessOwner"].LookupId
    $ownerAccount = New-PnPUser -LoginName $ownerAccount 
    
    if ( $siteItem["$($columnPrefix)SiteURL"] -eq $null) {
        $siteUrl = GetUniqueUrlFromName -title $title
    }
    else {
        $siteUrl = $siteItem["$($columnPrefix)SiteURL"].Url
    }
    
    Write-Output -InputObject "`nProcessing $siteUrl"
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
    $urlToSiteDirectory = "$tenantURL$siteDirectorySiteUrl$siteDirectoryList"

    EnsureSite -siteEntryId $siteItem["ID"] -title $title -siteUrl $siteUrl -description $description `
        -siteCollectionAdmin $primarySiteCollectionAdmin `
        -owner $ownerAccount `
        -ownerAddresses $businessOwnerEmailAddress `
        -members $members `
        -visitors $visitors

    if ($? -eq $true -and ($editor -ne "SharePoint App" -or $Force)) {
        EnsureSecurityGroups -siteUrl $siteUrl -title $title -owners $owners -members $members -visitors $visitors
        
        Apply-TemplateConfigurations -siteUrl $siteUrl -siteItem $siteItem -templateConfigurationItems $templateConfigurationItems -baseModuleItems $baseModuleItems -subModuleItems $subModuleItems

        SyncMetadata -siteUrl $siteUrl -title $title -description $description   

        SetRequestAccessEmail -siteUrl $siteUrl -ownersEmail ($ownerEmailAddresses -join ',')        
        if ($siteStatus -ne 'Provisioned') {
            SendReadyEmail -siteUrl $siteUrl -toEmail $orderedByUser.Email -ccEmails $businessOwnerEmailAddress -title $title
            SetSiteUrl -siteItem $siteItem -siteUrl $siteUrl -title $title
            UpdateStatus -id $siteItem["ID"] -status 'Provisioned'
        }        
    }
}
Disconnect-PnPOnline
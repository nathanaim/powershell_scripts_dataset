﻿
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Site server where the SMS Provider is installed")]
    [parameter(ParameterSetName="All")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Specify a single or set of apps you'd like to create")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Word","Excel","PowerPoint","OneDrive","Outlook","OneNote","OfficeMobile")]
    [string[]]$AppName,
    [parameter(Mandatory=$true, ParameterSetName="All", HelpMessage="Create an application for all of the Microsoft Office apps")]
    [ValidateNotNullOrEmpty()]
    [switch]$All
)
Begin {
    
    try {
        Write-Verbose -Message "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug -Message "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
    
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        try {
            Import-Module (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
            if ((Get-PSDrive $SiteCode -ErrorAction SilentlyContinue -Verbose:$false | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message) $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }
    
    $AppLinksTable = @{
        "AndroidWord" = "https://play.google.com/store/apps/details?id=com.microsoft.office.word&hl=en"
        "iOSWord" = "https://itunes.apple.com/us/app/microsoft-word/id586447913?mt=8"
        "AndroidExcel" = "https://play.google.com/store/apps/details?id=com.microsoft.office.excel&hl=en"
        "iOSExcel" = "https://itunes.apple.com/us/app/microsoft-excel/id586683407?mt=8"
        "AndroidPowerPoint" = "https://play.google.com/store/apps/details?id=com.microsoft.office.powerpoint&hl=en"
        "iOSPowerPoint" = "https://itunes.apple.com/us/app/microsoft-powerpoint/id586449534?mt=8"
        "AndroidOneDrive" = "https://play.google.com/store/apps/details?id=com.microsoft.skydrive&hl=en"
        "iOSOneDrive" = "https://itunes.apple.com/us/app/onedrive-cloud-storage-for/id477537958?mt=8"
        "AndroidOutlook" = "https://play.google.com/store/apps/details?id=com.microsoft.office.outlook&hl=en"
        "iOSOutlook" = "https://itunes.apple.com/us/app/microsoft-outlook/id951937596?mt=8"
        "AndroidOfficeMobile" = "https://play.google.com/store/apps/details?id=com.microsoft.office.officehub&hl=en"
        "iOSOneNote" = "https://itunes.apple.com/us/app/microsoft-onenote-lists-handwriting/id410395246?mt=8"
    }
    
    $AppNameTable = @{
        "Word" = "Word"
        "Excel" = "Excel"
        "PowerPoint" = "PowerPoint"
        "OneDrive" = "OneDrive"
        "Outlook" = "Outlook"
        "OneNote" = "OneNote"
        "OfficeMobile" = "Office Mobile"
    }
    
    Set-Location -Path $SiteDrive -ErrorAction Stop -Verbose:$false
}
Process {
    if ($All) {
        $AppName = @("Word","Excel","PowerPoint","OneDrive","Outlook","OneNote","OfficeMobile")
    }
    foreach ($App in $AppName) {
        
        Write-Verbose -Message "Determining store links for app '$($App)'"
        $AppLinks = $AppLinksTable.GetEnumerator() | Where-Object { $_.Key -match $App }
        $AndroidAppLink = $AppLinks | Where-Object { $_.Key -match "Android" } | Select-Object -ExpandProperty Value
        $iOSAppLink = $AppLinks | Where-Object { $_.Key -match "iOS" } | Select-Object -ExpandProperty Value
        
        $ApplicationName = $AppNameTable.GetEnumerator() | Where-Object { $_.Key -eq $App } | Select-Object -ExpandProperty Value
        
        try {
            $ApplicationName = "Microsoft " + $ApplicationName
            $ApplicationPublisher = "Microsoft"
            $ApplicationArguments = @{
                Name = $ApplicationName
                Publisher = $ApplicationPublisher
                ReleaseDate = (Get-Date)
                LocalizedApplicationName = $ApplicationName
                ErrorAction = "Stop"
                Verbose = $false
            }
            Write-Verbose -Message "Starting to create application '$($ApplicationName)' with deployment types"
            New-CMApplication @ApplicationArguments | Out-Null
            Write-Verbose -Message "Successfully created application '$($ApplicationName)'"
            
            if ($AndroidAppLink -ne $null) {
                $DeploymentTypeName = $ApplicationName + " - App Package for Android from Google Play"
                $AndroidDeploymentTypeArguments = @{
                    ApplicationName = $ApplicationName
                    DeploymentTypeName = $DeploymentTypeName
                    AndroidGooglePlayInstaller = $true
                    InstallationFileLocation = $AndroidAppLink
                    ErrorAction = "Stop"
                    Verbose = $false
                }
                Add-CMDeploymentType @AndroidDeploymentTypeArguments
                Write-Verbose -Message "Successfully created Android deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'"
            }
            
            if ($iOSAppLink -ne $null) {
                $DeploymentTypeName = $ApplicationName + " - App Package for iOS from App Store"
                $iOSDeploymentTypeArguments = @{
                    ApplicationName = $ApplicationName
                    DeploymentTypeName = $DeploymentTypeName
                    IosAppStoreInstaller = $true
                    InstallationFileLocation = $iOSAppLink
                    ErrorAction = "Stop"
                    Verbose = $false
                }
                Add-CMDeploymentType @iOSDeploymentTypeArguments
                Write-Verbose -Message "Successfully created iOS deployment type '$($DeploymentTypeName)' for application '$($ApplicationName)'"
            }
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message
        }
    }
}
End {
    
    Set-Location -Path $PSScriptRoot
}
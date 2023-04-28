﻿
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a valid path to where the XML file containing the Security Scope data export will be stored")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
        if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
            Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters"
        }
        else {
            if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
                return $true
            }
            else {
                Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extensions are '.xml'"
            }
        }
    })]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Will overwrite any existing XML files specified in the Path parameter.")]
    [switch]$Force,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress
)
Begin {
    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }

    
    if ([System.IO.File]::Exists($Path)) {
        if (-not($PSBoundParameters["Force"])) {
            Write-Warning -Message "Error creating '$($Path)', file already exists" ; break
        }
    }
}
Process {
    
    if ($PSBoundParameters["ShowProgress"]) {
        $ParentProgressCount = 0
        $ChildProgressCount = 0
    }

    
    $XMLData = New-Object -TypeName System.Xml.XmlDocument

    
    $XMLRoot = $XMLData.CreateElement("ConfigurationManager")
    $XMLData.AppendChild($XMLRoot) | Out-Null
    $XMLRoot.SetAttribute("Description", "Export of Security Scope object relations")

    
    $SecurityScopes = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SecuredCategory -ComputerName $SiteServer | Where-Object { $_.CategoryID -notlike "SMS*" }
    if ($SecurityScopes -ne $null) {
        
        $SecurityScopesCount = ($SecurityScopes | Measure-Object).Count

        
        foreach ($SecurityScope in $SecurityScopes) {
            if ($PSBoundParameters["ShowProgress"]) {
                $ParentProgressCount++
                Write-Progress -Activity "Enumerating Security Scopes" -Id 1 -Status "$($ParentProgressCount) / $($SecurityScopesCount)" -CurrentOperation "Current Security Scope: $($SecurityScope.CategoryName)" -PercentComplete (($ParentProgressCount / $SecurityScopesCount) * 100)
            }

            
            Write-Verbose -Message "Processing Security Scope: $($SecurityScope.CategoryName)"
            $SecurityScopeObjects = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SecuredCategoryMembership -ComputerName $SiteServer -Filter "CategoryID like '$($SecurityScope.CategoryID)'"
            if ($SecurityScopeObjects -ne $null) {
                if ($PSBoundParameters["ShowProgress"]) {
                    $ChildProgressCount = 0
                }

                
                $RelationsCount = ($SecurityScopeObjects | Measure-Object).Count

                
                $XMLSecurityScope = $XMLData.CreateElement("SecurityScope")
                $XMLSecurityScope.SetAttribute("CategoryName", $SecurityScope.CategoryName)
                $XMLData.ConfigurationManager.AppendChild($XMLSecurityScope) | Out-Null

                
                foreach ($SecurityScopeObject in $SecurityScopeObjects) {
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ChildProgressCount++
                        Write-Progress -Activity "Processing Security Scope relations" -Id 2 -ParentId 1 -Status "$($ChildProgressCount) / $($RelationsCount)" -CurrentOperation "Current Security Scope: $($SecurityScopeObject.ObjectKey)" -PercentComplete (($ChildProgressCount / $RelationsCount) * 100)
                    }

                    
                    $XMLRelation = $XMLData.CreateElement("Relation")
                    $XMLSecurityScope.AppendChild($XMLRelation) | Out-Null

                    
                    $XMLObjectKey = $XMLData.CreateElement("ObjectKey")
                    $XMLObjectKey.InnerText = $SecurityScopeObject.ObjectKey

                    
                    $XMLObjectTypeID = $XMLData.CreateElement("ObjectTypeID")
                    $XMLObjectTypeID.InnerText = $SecurityScopeObject.ObjectTypeID

                    
                    $XMLRelation.AppendChild($XMLObjectKey) | Out-Null
                    $XMLRelation.AppendChild($XMLObjectTypeID) | Out-Null
                }
                Write-Verbose -Message "Finished exporting '$($SecurityScope.CategoryName)' relations to '$($Path)'"
            }
            else {
                Write-Verbose -Message "Security Scope '$($SecurityScope.CategoryName)' does not have any object relations"
            }
        }
    }
    else {
        Write-Warning -Message "Unable to locate any Security Scopes eligible for export" ; break
    }
}
End {
    
    $XMLData.Save($Path) | Out-Null
}
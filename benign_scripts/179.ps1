﻿function Get-SCCMUserCollectionDeployment
{


    [CmdletBinding()]
    PARAM
    (
        [Parameter(Mandatory)]
        [Alias('SamAccountName')]
        $UserName,

        [Parameter(Mandatory)]
        $SiteCode,

        [Parameter(Mandatory)]
        $ComputerName,

        [Alias('RunAs')]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateSet('Required', 'Available')]
        $Purpose
    )

    BEGIN
    {
        
        
        
        if ($UserName -like '*\*') { $UserName = ($UserName -split '\\')[1] }

        
        $Splatting = @{
            ComputerName = $ComputerName
            NameSpace = "root\SMS\Site_$SiteCode"
        }

        IF ($PSBoundParameters['Credential'])
        {
            $Splatting.Credential = $Credential
        }

        Switch ($Purpose)
        {
            "Required" { $DeploymentIntent = 0 }
            "Available" { $DeploymentIntent = 2 }
            default { $DeploymentIntent = "NA" }
        }

        Function Get-DeploymentIntentName
        {
                PARAM(
                [Parameter(Mandatory)]
                $DeploymentIntent
                )
                    PROCESS
                    {
                if ($DeploymentIntent = 0) { Write-Output "Required" }
                if ($DeploymentIntent = 2) { Write-Output "Available" }
                if ($DeploymentIntent -ne 0 -and $DeploymentIntent -ne 2) { Write-Output "NA" }
            }
        }


    }
    PROCESS
    {
        
        $User = Get-WMIObject @Splatting -Query "Select * From SMS_R_User WHERE UserName='$UserName'"

        
        Get-WmiObject -Class sms_fullcollectionmembership @splatting -Filter "ResourceID = '$($user.resourceid)'" |
        ForEach-Object {

            
            $Collections = Get-WmiObject @splatting -Query "Select * From SMS_Collection WHERE CollectionID='$($_.Collectionid)'"


            
            Foreach ($Collection in $collections)
            {
                IF ($DeploymentIntent -eq 'NA')
                {
                    
                    $Deployments = (Get-WmiObject @splatting -Query "Select * From SMS_DeploymentInfo WHERE CollectionID='$($Collection.CollectionID)'")
                }
                ELSE
                {
                    $Deployments = (Get-WmiObject @splatting -Query "Select * From SMS_DeploymentInfo WHERE CollectionID='$($Collection.CollectionID)' AND DeploymentIntent='$DeploymentIntent'")
                }

                Foreach ($Deploy in $Deployments)
                {

                    
                    $Properties = @{
                        UserName = $UserName
                        ComputerName = $ComputerName
                        CollectionName = $Deploy.CollectionName
                        CollectionID = $Deploy.CollectionID
                        DeploymentID = $Deploy.DeploymentID
                        DeploymentName = $Deploy.DeploymentName
                        DeploymentIntent = $deploy.DeploymentIntent
                        DeploymentIntentName = (Get-DeploymentIntentName -DeploymentIntent $deploy.DeploymentIntent)
                        TargetName = $Deploy.TargetName
                        TargetSubName = $Deploy.TargetSubname

                    }

                    
                    New-Object -TypeName PSObject -prop $Properties
                }
            }
        }
    }
}

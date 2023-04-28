﻿
[CmdletBinding(DefaultParameterSetName="All")]
PARAM (
    [parameter(Mandatory = $true)]
    $Credential,
    [parameter(Mandatory = $true)]
    $Vcenter,
    [Parameter(mandatory=$true,ParameterSetName = "All")]
    [Switch]$AllVib,
    [Parameter(mandatory=$true,ParameterSetName = "VIBName")]
    $VibName,
    [Parameter(mandatory=$true,ParameterSetName = "VIBVendor")]
    $VibVendor
)
BEGIN
{
    TRY
    {
        
        IF (-not (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue'))
        {
            Write-Verbose -Message "BEGIN - Loading Vmware Snapin VMware.VimAutomation.Core..."
            Add-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction Stop -ErrorVariable ErrorBeginAddPssnapin
        }

        
        IF (-not ($global:DefaultVIServer.count -gt 0))
        {
            Write-Verbose -Message "BEGIN - Currently not connected to a vCenter..."
            $Vcenter = Read-Host -Prompt "You are not connected to a VMware vCenter, Please enter the FQDN or IP of the vCenter"

            IF ((Read-Host -Prompt "You are currently logged as: $($env:username). Do you want to specify different credential ? (Y/N)") -eq 'Y')
            {
                Connect-VIServer -Server $Vcenter -credential (Get-Credential) -ErrorAction Stop -ErrorVariable ErrorBeginConnectViServer
            }
            ELSE
            {
                Connect-VIServer -Server $Vcenter -ErrorAction Stop -ErrorVariable ErrorBeginConnectViServer
            }
        }
    }
    CATCH
    {
        Write-Warning -Message "Can't Connect to the Vcenter Server $vcenter"
        Write-Warning -Message $Error[0].Exception.Message
    }
}
PROCESS
{
    TRY
    {
        $VMHosts = Get-VMHost -ErrorAction Stop -ErrorVariable ErrorGetVMhost | Where-Object { $_.ConnectionState -eq "Connected" }

        IF ($PSBoundParameters['AllVib'])
        {
            Foreach ($CurrentVMhost in $VMHosts)
            {
                TRY
                {
                    
                    $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                    
                    $ESXCLI.software.vib.list() |
                    ForEach-Object {
                        $VIB = $_
                        $Prop = [ordered]@{
                            'VMhost' = $CurrentVMhost.Name
                            'ID' = $VIB.ID
                            'Name' = $VIB.Name
                            'Vendor' = $VIB.Vendor
                            'Version' = $VIB.Version
                            'Status' = $VIB.Status
                            'ReleaseDate' = $VIB.ReleaseDate
                            'InstallDate' = $VIB.InstallDate
                            'AcceptanceLevel' = $VIB.AcceptanceLevel
                        }

                        
                        New-Object PSobject -Property $Prop
                    }
                }
                CATCH
                {
                    Write-Warning -Message "Something wrong happened with $($CurrentVMhost.name)"
                    Write-Warning -Message $Error[0].Exception.Message
                }
            }
        }
        IF ($PSBoundParameters['VibVendor'])
        {
            Foreach ($CurrentVMhost in $VMHosts)
            {
                TRY
                {
                    
                    $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                    
                    $ESXCLI.software.vib.list() | Where-object { $_.Vendor -eq $VibVendor } |
                    ForEach-Object
                    {
                        $VIB = $_
                        $Prop = [ordered]@{
                            'VMhost' = $CurrentVMhost.Name
                            'ID' = $VIB.ID
                            'Name' = $VIB.Name
                            'Vendor' = $VIB.Vendor
                            'Version' = $VIB.Version
                            'Status' = $VIB.Status
                            'ReleaseDate' = $VIB.ReleaseDate
                            'InstallDate' = $VIB.InstallDate
                            'AcceptanceLevel' = $VIB.AcceptanceLevel
                        }

                        
                        New-Object PSobject -Property $Prop
                    }
                }
                CATCH
                {
                    Write-Warning -Message "Something wrong happened with $($CurrentVMhost.name)"
                    Write-Warning -Message $Error[0].Exception.Message
                }
            }
        }
        IF ($PSBoundParameters['VibName'])
        {
            Foreach ($CurrentVMhost in $VMHosts)
            {
                TRY
                {
                    
                    $ESXCLI = Get-EsxCli -VMHost $CurrentVMhost.name
                    
                    $ESXCLI.software.vib.list() | Where-object { $_.Name -eq $VibName } |
                    ForEach-Object
                    {
                        $VIB = $_
                        $Prop = [ordered]@{
                            'VMhost' = $CurrentVMhost.Name
                            'ID' = $VIB.ID
                            'Name' = $VIB.Name
                            'Vendor' = $VIB.Vendor
                            'Version' = $VIB.Version
                            'Status' = $VIB.Status
                            'ReleaseDate' = $VIB.ReleaseDate
                            'InstallDate' = $VIB.InstallDate
                            'AcceptanceLevel' = $VIB.AcceptanceLevel
                        }

                        
                        New-Object PSobject -Property $Prop
                    }
                }
                CATCH
                {
                    Write-Warning -Message "Something wrong happened with $($CurrentVMhost.name)"
                    Write-Warning -Message $Error[0].Exception.Message
                }
            }
        }
    }
    CATCH
    {
        Write-Warning -Message "Something wrong happened in the script"
        IF ($ErrorGetVMhost) { Write-Warning -Message "Couldn't retrieve VMhosts" }
        Write-Warning -Message $Error[0].Exception.Message
    }
}

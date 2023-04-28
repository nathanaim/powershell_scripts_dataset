﻿














function Test-LoadBalancerCRUD-Public
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $job = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -AsJob
        $job | Wait-Job
		$actualLb = $job | Receive-Job

        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-NotNull $expectedLb.ResourceGuid
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        $list = Get-AzLoadBalancer -ResourceGroupName "*"
        Assert-True { @($list).Count -ge 0 }

        $list = Get-AzLoadBalancer -Name "*"
        Assert-True { @($list).Count -ge 0 }

        $list = Get-AzLoadBalancer -ResourceGroupName "*" -Name "*"
        Assert-True { @($list).Count -ge 0 }

        
        $job = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force -AsJob
		$job | Wait-Job
		$deleteLb = $job | Receive-Job
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicTcpReset
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -DomainNameLabel $domainNameLabel -Sku Standard

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol https -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP -EnableTcpReset
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -EnableTcpReset -LoadDistribution SourceIP -DisableOutboundSNAT
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -Sku Standard

        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqualObjectProperties $expectedLb.Sku $actualLb.Sku
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-NotNull $expectedLb.ResourceGuid
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count

        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath
        Assert-AreEqual "https" $expectedLb.Probes[0].Protocol

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual true $expectedLb.InboundNatRules[0].EnableTcpReset
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        Assert-AreEqual true $expectedLb.LoadBalancingRules[0].EnableTcpReset

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqualObjectProperties $expectedLb.Sku $list[0].Sku
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb

        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalDynamic
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress
        Assert-AreEqual "IPv4" $expectedLb.FrontendIPConfigurations[0].PrivateIpAddressVersion

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalStatic
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0] -PrivateIpAddress "10.0.1.5" -PrivateIpAddressVersion "IPv4"
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-AreEqual "10.0.1.5" $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress
        Assert-AreEqual "IPv4" $expectedLb.FrontendIPConfigurations[0].PrivateIpAddressVersion

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalHighlyAvailableBasicSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol All -FrontendPort 0 -BackendPort 0 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -LoadBalancingRule $lbrule -Sku Basic
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
		Assert-AreEqual 0 $expectedLb.LoadBalancingRules[0].FrontendPort
		Assert-AreEqual 0 $expectedLb.LoadBalancingRules[0].BackendPort
		Assert-AreEqual All $expectedLb.LoadBalancingRules[0].Protocol

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalHighlyAvailableStandardSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol All -FrontendPort 0 -BackendPort 0 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -LoadBalancingRule $lbrule -Sku Standard
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
		Assert-AreEqual 0 $expectedLb.LoadBalancingRules[0].FrontendPort
		Assert-AreEqual 0 $expectedLb.LoadBalancingRules[0].BackendPort
		Assert-AreEqual All $expectedLb.LoadBalancingRules[0].Protocol

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicNoInboundNATRule
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalUsingId
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName	
        Assert-AreEqual $expectedLb.Name $actualLb.Name	
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        
        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath
        
        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id
        
        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag
        
        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicUsingId
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddressId $publicip.Id
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName	
        Assert-AreEqual $expectedLb.Name $actualLb.Name	
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        
        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name
        
        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath
        
        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id
        
        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag
        
        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicNoLbRule
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        
        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}



function Test-LoadBalancerChildResource
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        
        
        $frontendName2 = Get-ResourceName
        $lb = $lb | Add-AzLoadBalancerFrontendIpConfig -Name $frontendName2 -Subnet $vnet.Subnets[0]

        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName2 $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual "Dynamic" $lb.FrontendIPConfigurations[1].PrivateIPAllocationMethod
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[1].Subnet.Id

        $lb = $lb | Set-AzLoadBalancerFrontendIpConfig -Name $frontendName2 -Subnet $vnet.Subnets[0] -PrivateIpAddress "10.0.1.5"
        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName2 $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual "Static" $lb.FrontendIPConfigurations[1].PrivateIPAllocationMethod
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[1].Subnet.Id
        Assert-AreEqual "10.0.1.5" $lb.FrontendIPConfigurations[1].PrivateIpAddress

        $frontendIpconfig = $lb | Get-AzLoadBalancerFrontendIpConfig -Name $frontendName2
        $frontendIpconfigList = $lb | Get-AzLoadBalancerFrontendIpConfig
        Assert-AreEqual 2 @($frontendIpconfigList).Count
        Assert-AreEqual $frontendName $frontendIpconfigList[0].Name
        Assert-AreEqual $frontendName2 $frontendIpconfigList[1].Name
        Assert-AreEqual $frontendIpconfig.Name $frontendIpconfigList[1].Name

        $lb = $lb | Remove-AzLoadBalancerFrontendIpConfig -Name $frontendName2
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count
        Assert-AreEqual $frontendName $lb.FrontendIPConfigurations[0].Name

        
        $backendAddressPoolName2 = Get-ResourceName
        $job =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2 | Set-AzLoadBalancer -AsJob
		$job | Wait-Job
		$lb = $job | Receive-Job

        Assert-AreEqual 2 @($lb.BackendAddressPools).Count
        Assert-AreEqual $backendAddressPoolName2 $lb.BackendAddressPools[1].Name

        $backendAddressPoolConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname| Get-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2
        $backendAddressPoolConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerBackendAddressPoolConfig
        Assert-AreEqual 2 @($backendAddressPoolconfigList).Count
        Assert-AreEqual $backendAddressPoolName $backendAddressPoolConfigList[0].Name
        Assert-AreEqual $backendAddressPoolName2 $backendAddressPoolConfigList[1].Name
        Assert-AreEqual $backendAddressPoolConfig.Name $backendAddressPoolConfigList[1].Name

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.BackendAddressPools).Count
        Assert-AreEqual $backendAddressPoolName $lb.BackendAddressPools[0].Name

        
        $probeName2 = Get-ResourceName
        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 81 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzLoadBalancer

        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 85 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 85 $lb.Probes[1].Port

        $probeConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerProbeConfig -Name $probeName2
        $probeConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerProbeConfig
        Assert-AreEqual 2 @($probeConfigList).Count
        Assert-AreEqual $probeName $probeConfigList[0].Name
        Assert-AreEqual $probeName2 $probeConfigList[1].Name
        Assert-AreEqual $probeConfig.Name $probeConfigList[1].Name

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerProbeConfig -Name $probeName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.Probes).Count
        Assert-AreEqual $probeName $lb.Probes[0].Name

        
        $inboundNatRuleName2 = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPort 3350 -BackendPort 3350 -IdleTimeoutInMinutes 17 -EnableFloatingIP | Set-AzLoadBalancer
        
        Assert-AreEqual 2 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName2 $lb.InboundNatRules[1].Name
        Assert-AreEqual 3350 $lb.InboundNatRules[1].FrontendPort
        Assert-AreEqual 3350 $lb.InboundNatRules[1].BackendPort
        Assert-AreEqual true $lb.InboundNatRules[1].EnableFloatingIP

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPort 3352 -BackendPort 3351 -IdleTimeoutInMinutes 17 | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName2 $lb.InboundNatRules[1].Name
        Assert-AreEqual 3352 $lb.InboundNatRules[1].FrontendPort
        Assert-AreEqual 3351 $lb.InboundNatRules[1].BackendPort
        Assert-AreEqual false $lb.InboundNatRules[1].EnableFloatingIP

        $inboundNatRuleConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2
        $inboundNatRuleConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatRuleConfig
        Assert-AreEqual 2 @($inboundNatRuleConfigList).Count
        Assert-AreEqual $inboundNatRuleName $inboundNatRuleConfigList[0].Name
        Assert-AreEqual $inboundNatRuleName2 $inboundNatRuleConfigList[1].Name
        Assert-AreEqual $inboundNatRuleConfig.Name $inboundNatRuleConfigList[1].Name

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.InboundNatRules).Count
        Assert-AreEqual $inboundNatRuleName $lb.InboundNatRules[0].Name

        
        $lbruleName2 = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerRuleConfig -Name $lbruleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -BackendAddressPoolId $lb.BackendAddressPools[0].Id -ProbeId $lb.Probes[0].Id -Protocol Tcp -FrontendPort 82 -BackendPort 83 -IdleTimeoutInMinutes 15 -LoadDistribution SourceIP| Set-AzLoadBalancer
        
        Assert-AreEqual 2 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName2 $lb.LoadBalancingRules[1].Name
        Assert-AreEqual 82 $lb.LoadBalancingRules[1].FrontendPort
        Assert-AreEqual 83 $lb.LoadBalancingRules[1].BackendPort
        Assert-AreEqual false $lb.LoadBalancingRules[1].EnableFloatingIP
        Assert-AreEqual "SourceIP" $lb.LoadBalancingRules[1].LoadDistribution

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerRuleConfig -Name $lbruleName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -BackendAddressPoolId $lb.BackendAddressPools[0].Id -ProbeId $lb.Probes[0].Id -Protocol Tcp -FrontendPort 84 -BackendPort 84 -IdleTimeoutInMinutes 17 -EnableFloatingIP | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName2 $lb.LoadBalancingRules[1].Name
        Assert-AreEqual 84 $lb.LoadBalancingRules[1].FrontendPort
        Assert-AreEqual 84 $lb.LoadBalancingRules[1].BackendPort
        Assert-AreEqual true $lb.LoadBalancingRules[1].EnableFloatingIP
        Assert-AreEqual "Default" $lb.LoadBalancingRules[1].LoadDistribution

        $lbruleConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerRuleConfig -Name $lbruleName2
        $lbruleConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerRuleConfig
        Assert-AreEqual 2 @($inboundNatRuleConfigList).Count
        Assert-AreEqual $lbruleName $lbruleConfigList[0].Name
        Assert-AreEqual $lbruleName2 $lbruleConfigList[1].Name
        Assert-AreEqual $lbruleConfig.Name $lbruleConfigList[1].Name

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerRuleConfig -Name $lbruleName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.LoadBalancingRules).Count
        Assert-AreEqual $lbruleName $lb.LoadBalancingRules[0].Name

        
        $deleteLb = $lb | Remove-AzLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerSet
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfigurationId $frontend.Id -BackendAddressPoolId $backendAddressPool.Id -ProbeId $probe.Id -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
    
        
        $probeName2 = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerProbeConfig -Name $probeName2 -RequestPath healthcheck2.aspx -Protocol http -Port 81 -IntervalInSeconds 16 -ProbeCount 3 | Set-AzLoadBalancer

        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.Probes).Count
        Assert-AreEqual $probeName2 $lb.Probes[1].Name
        Assert-AreEqual "healthcheck2.aspx" $lb.Probes[1].RequestPath
        Assert-AreEqual 81 $lb.Probes[1].Port

        
        $deleteLb = $lb | Remove-AzLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-CreateEmptyLoadBalancer
{
    
    $rgname = Get-ResourceGroupName
    $lbName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual $lbName $lb.Name
        Assert-AreEqual 0 @($lb.FrontendIpConfigurations).Count
        Assert-AreEqual 0 @($lb.BackendAddressPools).Count
        Assert-AreEqual 0 @($lb.Probes).Count
        Assert-AreEqual 0 @($lb.InboundNatRules).Count
        Assert-AreEqual 0 @($lb.LoadBalancingRules).Count

        
        $deleteLb = $lb | Remove-AzLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancer-NicAssociation
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName1 = Get-ResourceName
    $inboundNatRuleName2 = Get-ResourceName
    $lbruleName = Get-ResourceName
    $nicname1 = Get-ResourceName
    $nicname2 = Get-ResourceName
    $nicname3 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule1 = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName1 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $inboundNatRule2 = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3391 -BackendPort 3392
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule1,$inboundNatRule2 -LoadBalancingRule $lbrule
        
        
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-NotNull $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count

        Assert-Null $lb.InboundNatRules[0].BackendIPConfiguration
        Assert-Null $lb.InboundNatRules[1].BackendIPConfiguration
        Assert-AreEqual 0 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        
        $nic1 = New-AzNetworkInterface -Name $nicname1 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]
        $nic2 = New-AzNetworkInterface -Name $nicname2 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]
        $nic3 = New-AzNetworkInterface -Name $nicname3 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0]

        
        $nic1.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($lb.BackendAddressPools[0]);
        $nic1.IpConfigurations[0].LoadBalancerInboundNatRules.Add($lb.InboundNatRules[0]);
        $nic2.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($lb.BackendAddressPools[0]);
        $nic3.IpConfigurations[0].LoadBalancerInboundNatRules.Add($lb.InboundNatRules[1]);

        
        $nic1 = $nic1 | Set-AzNetworkInterface
        $nic2 = $nic2 | Set-AzNetworkInterface
        $nic3 = $nic3 | Set-AzNetworkInterface

        
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        Assert-AreEqual $nic1.IpConfigurations[0].Id $lb.InboundNatRules[0].BackendIPConfiguration.Id
        Assert-AreEqual $nic3.IpConfigurations[0].Id $lb.InboundNatRules[1].BackendIPConfiguration.Id
        Assert-AreEqual 2 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancer-NicAssociationDuringCreate
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName1 = Get-ResourceName
    $inboundNatRuleName2 = Get-ResourceName
    $lbruleName = Get-ResourceName
    $nicname1 = Get-ResourceName
    $nicname2 = Get-ResourceName
    $nicname3 = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule1 = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName1 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $inboundNatRule2 = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName2 -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3391 -BackendPort 3392
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule1,$inboundNatRule2 -LoadBalancingRule $lbrule
        
        
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-NotNull $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count

        Assert-Null $lb.InboundNatRules[0].BackendIPConfiguration
        Assert-Null $lb.InboundNatRules[1].BackendIPConfiguration
        Assert-AreEqual 0 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        
        $nic1 = New-AzNetworkInterface -Name $nicname1 -ResourceGroupName $rgname -Location $location -Subnet $vnet.Subnets[0] -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0] -LoadBalancerInboundNatRule $lb.InboundNatRules[0]
        $nic2 = New-AzNetworkInterface -Name $nicname2 -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].Id
        $nic3 = New-AzNetworkInterface -Name $nicname3 -ResourceGroupName $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -LoadBalancerInboundNatRuleId $lb.InboundNatRules[1].Id

        
        $nic1 = $nic1 | Set-AzNetworkInterface
        $nic2 = $nic2 | Set-AzNetworkInterface
        $nic3 = $nic3 | Set-AzNetworkInterface

        
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        Assert-AreEqual $nic1.IpConfigurations[0].Id $lb.InboundNatRules[0].BackendIPConfiguration.Id
        Assert-AreEqual $nic3.IpConfigurations[0].Id $lb.InboundNatRules[1].BackendIPConfiguration.Id
        Assert-AreEqual 2 @($lb.BackendAddressPools[0].BackendIpConfigurations).Count

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerInboundNatPoolConfigCRUD-InternalLB  
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "West US"
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers" "West US"
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -SubnetId $vnet.Subnets[0].Id
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend 
        
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        $inboundNatPoolName = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname 
        $lb = $lb | Add-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPortRangeStart 3360 -FrontendPortRangeEnd 3362 -BackendPort 3370 | Set-AzLoadBalancer

        Assert-AreEqual 1 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName $lb.InboundNatPools[0].Name
        Assert-AreEqual 3360 $lb.InboundNatPools[0].FrontendPortRangeStart
        Assert-AreEqual 3362 $lb.InboundNatPools[0].FrontendPortRangeEnd
        Assert-AreEqual 3370 $lb.InboundNatPools[0].BackendPort
        Assert-AreEqual Tcp $lb.InboundNatPools[0].Protocol

        $inboundNatPoolName2 = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Udp -FrontendPortRangeStart 3366 -FrontendPortRangeEnd 3368 -BackendPort 3376 | Set-AzLoadBalancer
        
        Assert-AreEqual 2 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName2 $lb.InboundNatPools[1].Name
        Assert-AreEqual 3366 $lb.InboundNatPools[1].FrontendPortRangeStart
        Assert-AreEqual 3368 $lb.InboundNatPools[1].FrontendPortRangeEnd
        Assert-AreEqual 3376 $lb.InboundNatPools[1].BackendPort
        Assert-AreEqual Udp $lb.InboundNatPools[1].Protocol

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPortRangeStart 3363 -FrontendPortRangeEnd 3364 -BackendPort 3373 | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName2 $lb.InboundNatPools[1].Name
        Assert-AreEqual 3363 $lb.InboundNatPools[1].FrontendPortRangeStart
        Assert-AreEqual 3364 $lb.InboundNatPools[1].FrontendPortRangeEnd
        Assert-AreEqual 3373 $lb.InboundNatPools[1].BackendPort
        Assert-AreEqual Tcp $lb.InboundNatPools[1].Protocol


        $inboundNatPoolConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2
        $inboundNatPoolConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatPoolConfig
        Assert-AreEqual 2 @($inboundNatPoolConfigList).Count
        Assert-AreEqual $inboundNatPoolName $inboundNatPoolConfigList[0].Name
        Assert-AreEqual $inboundNatPoolName2 $inboundNatPoolConfigList[1].Name
        Assert-AreEqual $inboundNatPoolConfig.Name $inboundNatPoolConfigList[1].Name

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName $lb.InboundNatPools[0].Name

        
        $deleteLb = $lb | Remove-AzLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerInboundNatPoolConfigCRUD-PublicLB
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $inboundNatPoolName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement "West US"
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers" "West US"
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $inboundNatPool = New-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName -FrontendIPConfigurationId $frontend.Id -Protocol Tcp -FrontendPortRangeStart 3360 -FrontendPortRangeEnd 3362 -BackendPort 3370 
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -InboundNatPool $inboundNatPool
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-NotNull $expectedLb.ResourceGuid
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual 1 @($expectedLb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName $expectedLb.InboundNatPools[0].Name
        Assert-AreEqual 3360 $expectedLb.InboundNatPools[0].FrontendPortRangeStart
        Assert-AreEqual 3362 $expectedLb.InboundNatPools[0].FrontendPortRangeEnd
        Assert-AreEqual 3370 $expectedLb.InboundNatPools[0].BackendPort
        Assert-AreEqual Tcp $expectedLb.InboundNatPools[0].Protocol
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatPools[0].FrontendIPConfiguration.Id

        
        $inboundNatPoolName2 = Get-ResourceName
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname 
        $lb = Add-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $lb -Name $inboundNatPoolName2 -FrontendIPConfiguration $lb.FrontendIPConfigurations[0] -Protocol Udp -FrontendPortRangeStart 3366 -FrontendPortRangeEnd 3368 -BackendPort 3376 | Set-AzLoadBalancer
        
        Assert-AreEqual 2 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName2 $lb.InboundNatPools[1].Name
        Assert-AreEqual 3366 $lb.InboundNatPools[1].FrontendPortRangeStart
        Assert-AreEqual 3368 $lb.InboundNatPools[1].FrontendPortRangeEnd
        Assert-AreEqual 3376 $lb.InboundNatPools[1].BackendPort
        Assert-AreEqual Udp $lb.InboundNatPools[1].Protocol

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2 -FrontendIPConfigurationId $lb.FrontendIPConfigurations[0].Id -Protocol Tcp -FrontendPortRangeStart 3363 -FrontendPortRangeEnd 3364 -BackendPort 3373 | Set-AzLoadBalancer
        Assert-AreEqual 2 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName2 $lb.InboundNatPools[1].Name
        Assert-AreEqual 3363 $lb.InboundNatPools[1].FrontendPortRangeStart
        Assert-AreEqual 3364 $lb.InboundNatPools[1].FrontendPortRangeEnd
        Assert-AreEqual 3373 $lb.InboundNatPools[1].BackendPort
        Assert-AreEqual Tcp $lb.InboundNatPools[1].Protocol

        $inboundNatPoolConfig = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2
        $inboundNatPoolConfigList = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerInboundNatPoolConfig
        Assert-AreEqual 2 @($inboundNatPoolConfigList).Count
        Assert-AreEqual $inboundNatPoolName $inboundNatPoolConfigList[0].Name
        Assert-AreEqual $inboundNatPoolName2 $inboundNatPoolConfigList[1].Name
        Assert-AreEqual $inboundNatPoolConfig.Name $inboundNatPoolConfigList[1].Name

        $lb =  Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerInboundNatPoolConfig -Name $inboundNatPoolName2 | Set-AzLoadBalancer
        Assert-AreEqual 1 @($lb.InboundNatPools).Count
        Assert-AreEqual $inboundNatPoolName $lb.InboundNatPools[0].Name

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerMultiVip-Public
{
    
    $rgname = Get-ResourceGroupName
    $publicIp1Name = Get-ResourceName
	$publicIp2Name = Get-ResourceName
	$publicIp3Name = Get-ResourceName
	$publicIp4Name = Get-ResourceName
    $lbName = Get-ResourceName
    $frontend1Name = Get-ResourceName
	$frontend2Name = Get-ResourceName
	$frontend3Name = Get-ResourceName
	$frontend4Name = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 

        
        $publicip1 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp1Name -location $location -AllocationMethod Dynamic
		$publicip2 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp2Name -location $location -AllocationMethod Dynamic
		$publicip3 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp3Name -location $location -AllocationMethod Dynamic
		$publicip4 = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp4Name -location $location -AllocationMethod Dynamic

        
        $frontend1 = New-AzLoadBalancerFrontendIpConfig -Name $frontend1Name -PublicIpAddress $publicip1
		$frontend2 = New-AzLoadBalancerFrontendIpConfig -Name $frontend2Name -PublicIpAddressId $publicip2.Id

        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend1 -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend2 -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend1,$frontend2  -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-NotNull $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-NotNull $lb.ResourceGuid
        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontend1Name $lb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip1.Id $lb.FrontendIPConfigurations[0].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[0].Subnet
		
		Assert-AreEqual $frontend2Name $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual $publicip2.Id $lb.FrontendIPConfigurations[1].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[1].Subnet
		
        Assert-AreEqual $backendAddressPoolName $lb.BackendAddressPools[0].Name
		
        Assert-AreEqual $probeName $lb.Probes[0].Name
        Assert-NotNull $lb.Probes[0].RequestPath
		
        Assert-AreEqual $inboundNatRuleName $lb.InboundNatRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $lb.InboundNatRules[0].FrontendIPConfiguration.Id
		
        Assert-AreEqual $lbruleName $lb.LoadBalancingRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $lb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $lb.BackendAddressPools[0].Id $lb.LoadBalancingRules[0].BackendAddressPool.Id

		
		$publicip1 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp1Name
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $publicip1.IpConfiguration.Id

		$publicip2 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp2Name
        Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $publicip2.IpConfiguration.Id

		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerFrontendIpConfig -Name $frontend3Name -PublicIpAddress $publicip3 | Set-AzLoadBalancer
		Assert-AreEqual 3 @($lb.FrontendIPConfigurations).Count

		Assert-AreEqual $frontend3Name $lb.FrontendIPConfigurations[2].Name
        Assert-AreEqual $publicip3.Id $lb.FrontendIPConfigurations[2].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[2].Subnet
		
		$publicip3 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp3Name
        Assert-AreEqual $lb.FrontendIPConfigurations[2].Id $publicip3.IpConfiguration.Id

		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerFrontendIpConfig -Name $frontend3Name -PublicIpAddress $publicip4 | Set-AzLoadBalancer

		Assert-AreEqual 3 @($lb.FrontendIPConfigurations).Count

		Assert-AreEqual $frontend3Name $lb.FrontendIPConfigurations[2].Name
        Assert-AreEqual $publicip4.Id $lb.FrontendIPConfigurations[2].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[2].Subnet

		$publicip3 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp3Name
        Assert-Null $publicip3.IpConfiguration

		$publicip4 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp4Name
        Assert-AreEqual $lb.FrontendIPConfigurations[2].Id $publicip4.IpConfiguration.Id

		
		$frontendip = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerFrontendIpConfig -Name $frontend3Name

		Assert-AreEqual $frontend3Name $frontendip.Name
        Assert-AreEqual $publicip4.Id $frontendip.PublicIpAddress.Id
		Assert-Null $frontendip.Subnet

		
		$frontendips = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerFrontendIpConfig

		Assert-AreEqual 3 @($frontendips).Count

		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerFrontendIpConfig -Name $frontend3Name | Set-AzLoadBalancer
		Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count

		Assert-AreEqual $frontend1Name $lb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip1.Id $lb.FrontendIPConfigurations[0].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[0].Subnet
		
		Assert-AreEqual $frontend2Name $lb.FrontendIPConfigurations[1].Name
        Assert-AreEqual $publicip2.Id $lb.FrontendIPConfigurations[1].PublicIpAddress.Id
		Assert-Null $lb.FrontendIPConfigurations[1].Subnet

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
		$list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count

		
		$publicip1 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp1Name
        Assert-Null $publicip1.IpConfiguration

		$publicip2 = Get-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIp2Name
        Assert-Null $publicip2.IpConfiguration
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerMultiVip-Internal
{
	
    $rgname = Get-ResourceGroupName
    $subnet1Name = Get-ResourceName
	$subnet2Name = Get-ResourceName
	$vnetName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontend1Name = Get-ResourceName
	$frontend2Name = Get-ResourceName
	$frontend3Name = Get-ResourceName
	$frontend4Name = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation

        
        $subnet1 = New-AzVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix 10.0.0.0/24
		$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $subnet2Name -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet1,$subnet2

        
        $frontend1 = New-AzLoadBalancerFrontendIpConfig -Name $frontend1Name -Subnet $vnet.Subnets[0]
		$frontend2 = New-AzLoadBalancerFrontendIpConfig -Name $frontend2Name -SubnetId $vnet.Subnets[1].Id

        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend1 -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend2 -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend1,$frontend2  -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
        
        
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-NotNull $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-NotNull $lb.ResourceGuid
        Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontend1Name $lb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[0].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[0].PublicIpAddress
		
		Assert-AreEqual $frontend2Name $lb.FrontendIPConfigurations[1].Name
		Assert-AreEqual $vnet.Subnets[1].Id $lb.FrontendIPConfigurations[1].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[1].PublicIpAddress
				
        Assert-AreEqual $backendAddressPoolName $lb.BackendAddressPools[0].Name
		
        Assert-AreEqual $probeName $lb.Probes[0].Name
        Assert-NotNull $lb.Probes[0].RequestPath
		
        Assert-AreEqual $inboundNatRuleName $lb.InboundNatRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $lb.InboundNatRules[0].FrontendIPConfiguration.Id
		
        Assert-AreEqual $lbruleName $lb.LoadBalancingRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $lb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $lb.BackendAddressPools[0].Id $lb.LoadBalancingRules[0].BackendAddressPool.Id
		
		
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		Assert-AreEqual 1 @($vnet.Subnets[0].IpConfigurations).Count
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id
		Assert-AreEqual 1 @($vnet.Subnets[1].IpConfigurations).Count
		Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $vnet.Subnets[1].IpConfigurations[0].Id

		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Add-AzLoadBalancerFrontendIpConfig -Name $frontend3Name -Subnet $vnet.Subnets[1] | Set-AzLoadBalancer
		Assert-AreEqual 3 @($lb.FrontendIPConfigurations).Count
		
		Assert-AreEqual $frontend3Name $lb.FrontendIPConfigurations[2].Name
		Assert-AreEqual $vnet.Subnets[1].Id $lb.FrontendIPConfigurations[2].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[2].PublicIpAddress

		
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		Assert-AreEqual 1 @($vnet.Subnets[0].IpConfigurations).Count
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id
		Assert-AreEqual 2 @($vnet.Subnets[1].IpConfigurations).Count
		Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $vnet.Subnets[1].IpConfigurations[0].Id
		Assert-AreEqual $lb.FrontendIPConfigurations[2].Id $vnet.Subnets[1].IpConfigurations[1].Id

		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Set-AzLoadBalancerFrontendIpConfig -Name $frontend3Name -SubnetId $vnet.Subnets[0].Id | Set-AzLoadBalancer
		
		Assert-AreEqual 3 @($lb.FrontendIPConfigurations).Count
		
		Assert-AreEqual $frontend3Name $lb.FrontendIPConfigurations[2].Name
		Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[2].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[2].PublicIpAddress
		
		
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		Assert-AreEqual 2 @($vnet.Subnets[0].IpConfigurations).Count
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $vnet.Subnets[0].IpConfigurations[0].Id
		Assert-AreEqual $lb.FrontendIPConfigurations[2].Id $vnet.Subnets[0].IpConfigurations[1].Id
		Assert-AreEqual 1 @($vnet.Subnets[1].IpConfigurations).Count
		Assert-AreEqual $lb.FrontendIPConfigurations[1].Id $vnet.Subnets[1].IpConfigurations[0].Id
		
		
		$frontendip = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerFrontendIpConfig -Name $frontend3Name
		
		Assert-AreEqual $frontend3Name $frontendip.Name
		Assert-AreEqual $vnet.Subnets[0].Id $frontendip.Subnet.Id
		Assert-Null $frontendip.PublicIpAddress
		
		
		$frontendips = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Get-AzLoadBalancerFrontendIpConfig
		
		Assert-AreEqual 3 @($frontendips).Count
		
		
		$lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname | Remove-AzLoadBalancerFrontendIpConfig -Name $frontend3Name | Set-AzLoadBalancer
		Assert-AreEqual 2 @($lb.FrontendIPConfigurations).Count
		
		Assert-AreEqual $frontend1Name $lb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $lb.FrontendIPConfigurations[0].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[0].PublicIpAddress
		
		Assert-AreEqual $frontend2Name $lb.FrontendIPConfigurations[1].Name
		Assert-AreEqual $vnet.Subnets[1].Id $lb.FrontendIPConfigurations[1].Subnet.Id
		Assert-Null $lb.FrontendIPConfigurations[1].PublicIpAddress

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
		$list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count

		
		$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname
		Assert-AreEqual 0 @($vnet.Subnets[0].IpConfigurations).Count
		Assert-AreEqual 0 @($vnet.Subnets[1].IpConfigurations).Count

    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-SetLoadBalancerObjectAssignment
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" } 
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule
  
        
        Assert-AreEqual $rgname $lb.ResourceGroupName
        Assert-AreEqual $lbName $lb.Name
        Assert-NotNull $lb.Location
        Assert-AreEqual "Succeeded" $lb.ProvisioningState
        Assert-NotNull $lb.ResourceGuid
        Assert-AreEqual 1 @($lb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $lb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $lb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $lb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $lb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $lb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $lb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $lb.InboundNatRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $lb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $lb.LoadBalancingRules[0].Name
        Assert-AreEqual $lb.FrontendIPConfigurations[0].Id $lb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $lb.BackendAddressPools[0].Id $lb.LoadBalancingRules[0].BackendAddressPool.Id

		
		Assert-Null  $lb.LoadBalancingRules[0].Probe

		$lb.LoadBalancingRules[0].Probe = $lb.Probes[0]
		$lb = $lb | Set-AzLoadBalancer

		Assert-NotNull $lb.LoadBalancingRules[0].Probe
		Assert-AreEqual $lb.LoadBalancingRules[0].Probe.Id $lb.Probes[0].Id

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicBasicSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -Sku Basic
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqualObjectProperties $expectedLb.Sku $actualLb.Sku
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-NotNull $expectedLb.ResourceGuid
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqualObjectProperties $expectedLb.Sku $list[0].Sku
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalBasicSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Dynamic -DomainNameLabel $domainNameLabel

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -Sku Basic
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqualObjectProperties $expectedLb.Sku $actualLb.Sku
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqualObjectProperties $expectedLb.Sku $list[0].Sku
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-PublicStandardSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $publicIpName = Get-ResourceName
    $domainNameLabel = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    try
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet
        
        
        $publicip = New-AzPublicIpAddress -ResourceGroupName $rgname -name $publicIpName -location $location -AllocationMethod Static -DomainNameLabel $domainNameLabel -Sku Standard

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -PublicIpAddress $publicip
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP -DisableOutboundSNAT
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -Sku Standard
        
        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqualObjectProperties $expectedLb.Sku $actualLb.Sku
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-NotNull $expectedLb.ResourceGuid
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count

        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $publicip.Id $expectedLb.FrontendIPConfigurations[0].PublicIpAddress.Id
        Assert-Null $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqualObjectProperties $expectedLb.Sku $list[0].Sku
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerCRUD-InternalStandardSku
{
    
    $rgname = Get-ResourceGroupName
    $vnetName = Get-ResourceName
    $subnetName = Get-ResourceName
    $lbName = Get-ResourceName
    $frontendName = Get-ResourceName
    $backendAddressPoolName = Get-ResourceName
    $probeName = Get-ResourceName
    $inboundNatRuleName = Get-ResourceName
    $lbruleName = Get-ResourceName
    $rglocation = Get-ProviderLocation ResourceManagement
    $resourceTypeParent = "Microsoft.Network/loadBalancers"
    $location = Get-ProviderLocation $resourceTypeParent

    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval"} 
        
        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/16 -Subnet $subnet

        
        $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $vnet.Subnets[0]
        $backendAddressPool = New-AzLoadBalancerBackendAddressPoolConfig -Name $backendAddressPoolName
        $probe = New-AzLoadBalancerProbeConfig -Name $probeName -RequestPath healthcheck.aspx -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
        $inboundNatRule = New-AzLoadBalancerInboundNatRuleConfig -Name $inboundNatRuleName -FrontendIPConfiguration $frontend -Protocol Tcp -FrontendPort 3389 -BackendPort 3389 -IdleTimeoutInMinutes 15 -EnableFloatingIP
        $lbrule = New-AzLoadBalancerRuleConfig -Name $lbruleName -FrontendIPConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -Protocol Tcp -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 -EnableFloatingIP -LoadDistribution SourceIP -DisableOutboundSNAT
        $actualLb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location -FrontendIpConfiguration $frontend -BackendAddressPool $backendAddressPool -Probe $probe -InboundNatRule $inboundNatRule -LoadBalancingRule $lbrule -Sku Standard

        $expectedLb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname

        
        Assert-AreEqual $expectedLb.ResourceGroupName $actualLb.ResourceGroupName
        Assert-AreEqual $expectedLb.Name $actualLb.Name
        Assert-AreEqual $expectedLb.Location $actualLb.Location
        Assert-AreEqualObjectProperties $expectedLb.Sku $actualLb.Sku
        Assert-AreEqual "Succeeded" $expectedLb.ProvisioningState
        Assert-AreEqual 1 @($expectedLb.FrontendIPConfigurations).Count
        
        Assert-AreEqual $frontendName $expectedLb.FrontendIPConfigurations[0].Name
        Assert-AreEqual $vnet.Subnets[0].Id $expectedLb.FrontendIPConfigurations[0].Subnet.Id
        Assert-NotNull $expectedLb.FrontendIPConfigurations[0].PrivateIpAddress

        Assert-AreEqual $backendAddressPoolName $expectedLb.BackendAddressPools[0].Name

        Assert-AreEqual $probeName $expectedLb.Probes[0].Name
        Assert-AreEqual $probe.RequestPath $expectedLb.Probes[0].RequestPath

        Assert-AreEqual $inboundNatRuleName $expectedLb.InboundNatRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.InboundNatRules[0].FrontendIPConfiguration.Id

        Assert-AreEqual $lbruleName $expectedLb.LoadBalancingRules[0].Name
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Id $expectedLb.LoadBalancingRules[0].FrontendIPConfiguration.Id
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Id $expectedLb.LoadBalancingRules[0].BackendAddressPool.Id
        Assert-AreEqual true $expectedlb.LoadBalancingRules[0].DisableOutboundSNAT
        Assert-AreEqual true $actualLb.LoadBalancingRules[0].DisableOutboundSNAT

        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 1 @($list).Count
        Assert-AreEqual $expectedLb.Etag $list[0].Etag
        Assert-AreEqualObjectProperties $expectedLb.Sku $list[0].Sku
        Assert-AreEqual $expectedLb.FrontendIPConfigurations[0].Etag $list[0].FrontendIPConfigurations[0].Etag
        Assert-AreEqual $expectedLb.BackendAddressPools[0].Etag $list[0].BackendAddressPools[0].Etag
        Assert-AreEqual $expectedLb.InboundNatRules[0].Etag $list[0].InboundNatRules[0].Etag
        Assert-AreEqual $expectedLb.Probes[0].Etag $list[0].Probes[0].Etag
        Assert-AreEqual $expectedLb.LoadBalancingRules[0].Etag $list[0].LoadBalancingRules[0].Etag
        Assert-AreEqual $expectedlb.LoadBalancingRules[0].DisableOutboundSNAT $actualLb.LoadBalancingRules[0].DisableOutboundSNAT

        
        $deleteLb = Remove-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -PassThru -Force
        Assert-AreEqual true $deleteLb
        
        $list = Get-AzLoadBalancer -ResourceGroupName $rgname
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-LoadBalancerZones
{
    
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $subnetName = Get-ResourceName
    $vnetName = Get-ResourceName
    $frontendName = Get-ResourceName
    $zones = "1";
    $rglocation = Get-ProviderLocation ResourceManagement
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers" "Central US"

    try
     {
      
      $resourceGroup = New-AzResourceGroup -Name $rgname -Location $rglocation -Tags @{ testtag = "testval" }
      $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
      $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rgname -Location $location -AddressPrefix 10.0.0.0/8 -Subnet $subnet
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet
      $frontend = New-AzLoadBalancerFrontendIpConfig -Name $frontendName -Subnet $subnet -Zone $zones

      
      $actual = New-AzLoadBalancer -ResourceGroupName $rgname -name $rname -location $location -frontendIpConfiguration $frontend;
      $expected = Get-AzLoadBalancer -ResourceGroupName $rgname -name $rname
      Assert-AreEqual $expected.ResourceGroupName $actual.ResourceGroupName
      Assert-AreEqual $expected.Name $actual.Name
      Assert-AreEqual $expected.Location $actual.Location
      Assert-NotNull $expected.ResourceGuid
      Assert-AreEqual "Succeeded" $expected.ProvisioningState
      Assert-NotNull $expected.frontendIpConfigurations
      Assert-NotNull $expected.frontendIpConfigurations[0]
      Assert-NotNull $expected.frontendIpConfigurations[0].zones
      Assert-AreEqual $zones $expected.frontendIpConfigurations[0].zones[0]
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}


function Test-CreateSubresourcesOnEmptyLoadBalancer
{
    
    $rgname = Get-ResourceGroupName
    $lbName = Get-ResourceName
    $location = Get-ProviderLocation "Microsoft.Network/loadBalancers"
    
    $poolName = Get-ResourceName
    $ipConfigName = Get-ResourceName
    $natPoolName = Get-ResourceName
    $natRuleName = Get-ResourceName
    $probeName = Get-ResourceName
    $ruleName = Get-ResourceName
    
    $subnetName = Get-ResourceName
    $vnetName = Get-ResourceName
    
    try 
    {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location

        
        $subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.1.0/24
        $vnet = New-AzVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $vnetName -Subnet $subnet -AddressPrefix 10.0.0.0/8
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

        
        New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname -Location $location

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual $lbName $lb.Name
        Assert-AreEqual 0 @($lb.FrontendIpConfigurations).Count
        Assert-AreEqual 0 @($lb.BackendAddressPools).Count
        Assert-AreEqual 0 @($lb.Probes).Count
        Assert-AreEqual 0 @($lb.LoadBalancingRules).Count
        Assert-AreEqual 0 @($lb.InboundNatRules).Count
        Assert-AreEqual 0 @($lb.InboundNatPools).Count
        Assert-AreEqual 0 @($lb.OutboundRules).Count

        
        $lb = Add-AzLoadBalancerFrontendIpConfig -Name $ipConfigName -LoadBalancer $lb -Subnet $subnet
        $ipConfig = $lb.FrontendIpConfigurations[0]
        Assert-NotNull $ipConfig

        $lb = Add-AzLoadBalancerBackendAddressPoolConfig -Name $poolName -LoadBalancer $lb
        $lb = Add-AzLoadBalancerProbeConfig -Name $probeName -LoadBalancer $lb -Port 2000 -IntervalInSeconds 60 -ProbeCount 3
        $lb = Add-AzLoadBalancerRuleConfig -Name $ruleName -LoadBalancer $lb -FrontendIpConfiguration $ipConfig -Protocol Tcp -FrontendPort 1024 -BackendPort 2048
        $lb = Add-AzLoadBalancerInboundNatRuleConfig -Name $natRuleName -LoadBalancer $lb -FrontendIpConfiguration $ipConfig -FrontendPort 128 -BackendPort 256

        
        $lb = Set-AzLoadBalancer -LoadBalancer $lb

        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual 1 @($lb.FrontendIpConfigurations).Count
        Assert-AreEqual 1 @($lb.BackendAddressPools).Count
        Assert-AreEqual 1 @($lb.Probes).Count
        Assert-AreEqual 1 @($lb.LoadBalancingRules).Count
        Assert-AreEqual 1 @($lb.InboundNatRules).Count

        
        $lb = Remove-AzLoadBalancerInboundNatRuleConfig -LoadBalancer $lb -Name $natRuleName
        $lb = Add-AzLoadBalancerInboundNatPoolConfig -Name $natPoolName -LoadBalancer $lb -FrontendIpConfiguration $ipConfig -Protocol Tcp -FrontendPortRangeStart 444 -FrontendPortRangeEnd 445 -BackendPort 8080
        
        $lb = Set-AzLoadBalancer -LoadBalancer $lb
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual 0 @($lb.InboundNatRules).Count
        Assert-AreEqual 1 @($lb.InboundNatPools).Count

        
        $lb = Remove-AzLoadBalancerBackendAddressPoolConfig -LoadBalancer $lb -Name $poolName
        $lb = Remove-AzLoadBalancerProbeConfig -LoadBalancer $lb -Name $probeName
        $lb = Remove-AzLoadBalancerRuleConfig -LoadBalancer $lb -Name $ruleName
        $lb = Remove-AzLoadBalancerInboundNatPoolConfig -LoadBalancer $lb -Name $natPoolName

        $lb = Set-AzLoadBalancer -LoadBalancer $lb
        $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgname
        Assert-AreEqual 1 @($lb.FrontendIpConfigurations).Count
        Assert-AreEqual 0 @($lb.BackendAddressPools).Count
        Assert-AreEqual 0 @($lb.Probes).Count
        Assert-AreEqual 0 @($lb.LoadBalancingRules).Count
        Assert-AreEqual 0 @($lb.InboundNatRules).Count
        Assert-AreEqual 0 @($lb.InboundNatPools).Count
        Assert-AreEqual 0 @($lb.OutboundRules).Count

        
        $lb = Remove-AzLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name $ipConfigName
        
        $lb = Remove-AzLoadBalancerFrontendIpConfig -LoadBalancer $lb -Name $ipConfigName
        
        Assert-ThrowsContains { Set-AzLoadBalancer -LoadBalancer $lb } "Deleting all frontendIPConfigs"

        
        $deleteLb = $lb | Remove-AzLoadBalancer -PassThru -Force
        Assert-AreEqual true $deleteLb

        $list = Get-AzLoadBalancer | Where-Object { $_.ResourceGroupName -eq $rgname }
        Assert-AreEqual 0 @($list).Count
    }
    finally
    {
        
        Clean-ResourceGroup $rgname
    }
}

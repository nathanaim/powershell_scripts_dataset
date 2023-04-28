














function Test-AzureFirewallPolicyCRUD {
    
    $rgname = Get-ResourceGroupName
    $azureFirewallPolicyName = Get-ResourceName
    $azureFirewallPolicyAsJobName = Get-ResourceName
    $resourceTypeParent = "Microsoft.Network/FirewallPolicies"
    $location = "westcentralus"

    $ruleGroupName = Get-ResourceName

    
    $appRcName = "appRc"
    $appRcPriority = 400
    $appRcActionType = "Allow"

    $pipelineRcPriority = 154

    
    $appRc2Name = "appRc2"
    $appRc2Priority = 300
    $appRc2ActionType = "Deny"

    
    $appRule1Name = "appRule"
    $appRule1Desc = "desc1"
    $appRule1Fqdn1 = "*google.com"
    $appRule1Fqdn2 = "*microsoft.com"
    $appRule1Protocol1 = "http:80"
    $appRule1Port1 = 80
    $appRule1ProtocolType1 = "http"
    $appRule1Protocol2 = "https:443"
    $appRule1Port2 = 443
    $appRule1ProtocolType2 = "https"
    $appRule1SourceAddress1 = "192.168.0.0/16"

    
    $appRule2Name = "appRule2"
    $appRule2Fqdn1 = "*bing.com"
    $appRule2Protocol1 = "http:8080"
    $appRule2Protocol2 = "https:443"
    $appRule2Port1 = 8080
    $appRule2ProtocolType1 = "http"
    $appRule2SourceAddress1 = "192.168.0.0/16"

    
    $networkRcName = "networkRc"
    $networkRcPriority = 200
    $networkRcActionType = "Deny"

    
    $networkRule1Name = "networkRule"
    $networkRule1Desc = "desc1"
    $networkRule1SourceAddress1 = "10.0.0.0"
    $networkRule1SourceAddress2 = "111.1.0.0/24"
    $networkRule1DestinationAddress1 = "*"
    $networkRule1Protocol1 = "UDP"
    $networkRule1Protocol2 = "TCP"
    $networkRule1Protocol3 = "ICMP"
    $networkRule1DestinationPort1 = "90"

    
    $natRcName = "natRc"
    $natRcPriority = 200
    $natRcActionType = "Dnat"

    
    $natRule1Name = "natRule"
    $natRule1Desc = "desc1"
    $natRule1SourceAddress1 = "10.0.0.0"
    $natRule1SourceAddress2 = "111.1.0.0/24"
    $natRule1DestinationAddress1 = "1.2.3.4"
    $natRule1Protocol1 = "UDP"
    $natRule1Protocol2 = "TCP"
    $natRule1DestinationPort1 = "90"
    $natRule1TranslatedAddress = "10.1.2.3"
    $natRule1TranslatedPort = "91"

    try {
        
        $resourceGroup = New-AzResourceGroup -Name $rgname -Location $location -Tags @{ testtag = "testval" }
        
        
        $azureFirewallPolicy = New-AzFirewallPolicy -Name $azureFirewallPolicyName -ResourceGroupName $rgname -Location $location 

        
        $getAzureFirewallPolicy = Get-AzFirewallPolicy -Name $azureFirewallPolicyName -ResourceGroupName $rgname

        
        Assert-AreEqual $rgName $getAzureFirewallPolicy.ResourceGroupName
        Assert-AreEqual $azureFirewallPolicyName $getAzureFirewallPolicy.Name
        Assert-NotNull $getAzureFirewallPolicy.Location
        Assert-AreEqual (Normalize-Location $location) $getAzureFirewallPolicy.Location
        Assert-AreEqual "Alert" $getAzureFirewallPolicy.ThreatIntelMode


        
        $appRule = New-AzFirewallPolicyApplicationRule -Name $appRule1Name -Description $appRule1Desc -Protocol $appRule1Protocol1, $appRule1Protocol2 -TargetFqdn $appRule1Fqdn1, $appRule1Fqdn2 -SourceAddress $appRule1SourceAddress1
        $appRule2 = New-AzFirewallPolicyApplicationRule -Name $appRule2Name -Description $appRule1Desc -Protocol $appRule2Protocol1, $appRule2Protocol2 -TargetFqdn $appRule2Fqdn1 -SourceAddress $appRule2SourceAddress1

        
        $networkRule = New-AzFirewallPolicyNetworkRule -Name $networkRule1Name -Description $networkRule1Desc -Protocol $networkRule1Protocol1, $networkRule1Protocol2 -SourceAddress $networkRule1SourceAddress1, $networkRule1SourceAddress2 -DestinationAddress $networkRule1DestinationAddress1 -DestinationPort $networkRule1DestinationPort1

        
        $appRc = New-AzFirewallPolicyFilterRuleCollection -Name $appRcName -Priority $appRcPriority -Rule $appRule, $appRule2 -ActionType $appRcActionType
        
        $appRc2 = New-AzFirewallPolicyFilterRuleCollection -Name $appRc2Name -Priority $appRc2Priority -Rule $networkRule -ActionType $appRc2ActionType

        
        $natRc = New-AzFirewallPolicyNatRuleCollection -Name $networkRcName -Priority $natRcPriority -Rule $networkRule -TranslatedAddress $natRule1TranslatedAddress -TranslatedPort $natRule1TranslatedPort -ActionType $natRcActionType

        New-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroupName -Priority 100 -RuleCollection $appRc, $appRc2, $natRc -FirewallPolicyObject $azureFirewallPolicy


        
        $azureFirewallPolicy.ThreatIntelMode = "Deny"
        
        Set-AzFirewallPolicy -InputObject $azureFirewallPolicy
        
        $getAzureFirewallPolicy = Get-AzFirewallPolicy -Name $azureFirewallPolicyName -ResourceGroupName $rgName

        
        Assert-AreEqual $rgName $getAzureFirewallPolicy.ResourceGroupName
        Assert-AreEqual $azureFirewallPolicyName $getAzureFirewallPolicy.Name
        Assert-NotNull $getAzureFirewallPolicy.Location
        Assert-AreEqual $location $getAzureFirewallPolicy.Location
        Assert-AreEqual "Deny" $getAzureFirewallPolicy.ThreatIntelMode

        
        Assert-AreEqual 1 @($getAzureFirewallPolicy.RuleCollectionGroups).Count

        $getRg = Get-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroupName -AzureFirewallPolicy $getAzureFirewallPolicy

        Assert-AreEqual 3 @($getRg.properties.ruleCollection).Count

        $filterRuleCollection1 = $getRg.Properties.GetRuleCollectionByName($appRcName)
        $natRuleCollection = $getRg.Properties.GetRuleCollectionByName($networkRcName)

        
        Assert-AreEqual $appRcName $filterRuleCollection1.Name
        Assert-AreEqual $appRcPriority $filterRuleCollection1.Priority
        Assert-AreEqual $appRcActionType $filterRuleCollection1.Action.Type
        Assert-AreEqual 2 $filterRuleCollection1.Rules.Count

        $appRule = $filterRuleCollection1.GetRuleByName($appRule1Name)
        
        Assert-AreEqual $appRule1Name $appRule.Name

        Assert-AreEqual 1 $appRule.SourceAddresses.Count
        Assert-AreEqual $appRule1SourceAddress1 $appRule.SourceAddresses[0]

        Assert-AreEqual 2 $appRule.Protocols.Count 
        Assert-AreEqual $appRule1ProtocolType1 $appRule.Protocols[0].ProtocolType
        Assert-AreEqual $appRule1ProtocolType2 $appRule.Protocols[1].ProtocolType
        Assert-AreEqual $appRule1Port1 $appRule.Protocols[0].Port
        Assert-AreEqual $appRule1Port2 $appRule.Protocols[1].Port

        Assert-AreEqual 2 $appRule.TargetFqdns.Count 
        Assert-AreEqual $appRule1Fqdn1 $appRule.TargetFqdns[0]
        Assert-AreEqual $appRule1Fqdn2 $appRule.TargetFqdns[1]

        
        $natRule = $natRuleCollection.GetRuleByName($networkRcName)

        Assert-AreEqual $networkRcName $natRuleCollection.Name
        Assert-AreEqual $natRcPriority $natRuleCollection.Priority

        Assert-AreEqual $networkRule1Name $natRule.Name

        Assert-AreEqual 2 $natRule.SourceAddresses.Count 
        Assert-AreEqual $natRule1SourceAddress1 $natRule.SourceAddresses[0]
        Assert-AreEqual $natRule1SourceAddress2 $natRule.SourceAddresses[1]

        Assert-AreEqual 1 $natRule.DestinationAddresses.Count 

        Assert-AreEqual 2 $natRule.Protocols.Count 
        Assert-AreEqual $networkRule1Protocol1 $natRule.Protocols[0]
        Assert-AreEqual $networkRule1Protocol2 $natRule.Protocols[1]

        Assert-AreEqual 1 $natRule.DestinationPorts.Count 
        Assert-AreEqual $natRule1DestinationPort1 $natRule.DestinationPorts[0]

        Assert-AreEqual $natRule1TranslatedAddress $natRuleCollection.TranslatedAddress
        Assert-AreEqual $natRule1TranslatedPort $natRuleCollection.TranslatedPort


        $testPipelineRg = Get-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroupName -AzureFirewallPolicyName $getAzureFirewallPolicy.Name -ResourceGroupName $rgname
        $testPipelineRg|Set-AzFirewallPolicyRuleCollectionGroup -Priority $pipelineRcPriority
        $testPipelineRg = Get-AzFirewallPolicyRuleCollectionGroup -Name $ruleGroupName -AzureFirewallPolicyName $getAzureFirewallPolicy.Name -ResourceGroupName $rgname
        Assert-AreEqual $pipelineRcPriority $testPipelineRg.properties.Priority 

        $azureFirewallPolicyAsJob = New-AzFirewallPolicy -Name $azureFirewallPolicyAsJobName -ResourceGroupName $rgname -Location $location -AsJob
        $result = $azureFirewallPolicyAsJob | Wait-Job
        Assert-AreEqual "Completed" $result.State;
    }
    finally {
        
        Clean-ResourceGroup $rgname
    }
}
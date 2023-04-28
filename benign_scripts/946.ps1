


$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "myResourceGroup"
$accountName = "mycosmosaccount-$uniqueId" 
$databaseName = "database1"
$containerName = "container1"
$databaseResourceName = $accountName + "/sql/" + $databaseName
$containerResourceName = $accountName + "/sql/" + $databaseName + "/" + $containerName
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$databaseResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases"
$containerResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/databases/containers"

$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$accountProperties = @{
    "databaseAccountOfferType"="Standard";
    "locations"=$locations
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties



$databaseProperties = @{
    "resource"=@{ "id"=$databaseName };
    "options"=@{ "Throughput"= 400 }
} 
New-AzResource -ResourceType $databaseResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $databaseResourceName -PropertyObject $databaseProperties



$containerProperties = @{
    "resource"=@{
        "id"=$containerName; 
        "partitionKey"=@{
            "paths"=@("/myPartitionKey"); 
            "kind"="Hash";
            "version" = 2
        }; 
        "indexingPolicy"=@{
            "indexingMode"="Consistent"; 
            "includedPaths"= @(@{
                "path"="/*"
            });
            "excludedPaths"= @(@{
                "path"="/myPathToNotIndex/*"
            })
        }
    }
} 

New-AzResource -ResourceType $containerResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $containerResourceName -PropertyObject $containerProperties

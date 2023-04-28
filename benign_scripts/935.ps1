



$uniqueId=$(-join ((97..122) + (48..57) | Get-Random -Count 15 | % {[char]$_}))

$apiVersion = "2015-04-08"
$location = "West US 2"
$resourceGroupName = "mjbArmTest"
$accountName = "mycosmosaccount-$uniqueId" 
$apiType = "EnableTable"
$accountResourceType = "Microsoft.DocumentDb/databaseAccounts"
$tableName = "table1"
$tableResourceName = $accountName + "/table/" + $tableName
$tableResourceType = "Microsoft.DocumentDb/databaseAccounts/apis/tables"
$throughput = 400


$locations = @(
    @{ "locationName"="West US 2"; "failoverPriority"=0 },
    @{ "locationName"="East US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{ "defaultConsistencyLevel"="Session" }

$accountProperties = @{
    "capabilities"= @( @{ "name"=$apiType } );
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="false"
}

New-AzResource -ResourceType $accountResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName -Location $location `
    -Name $accountName -PropertyObject $accountProperties -Force



$tableProperties = @{
    "resource"=@{ "id"=$tableName };
    "options"=@{ "Throughput"= $throughput }
}
New-AzResource -ResourceType $tableResourceType `
    -ApiVersion $apiVersion -ResourceGroupName $resourceGroupName `
    -Name $tableResourceName -PropertyObject $tableProperties -Force

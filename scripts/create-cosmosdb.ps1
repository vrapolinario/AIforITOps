# Load variables from env.conf
$envFile = Join-Path $PSScriptRoot 'env.conf'
if (!(Test-Path $envFile)) {
	Write-Error "Environment file env.conf not found in $PSScriptRoot."
	exit 1
}
$envVars = @{}
foreach ($line in Get-Content $envFile) {
	if ($line -match '^(\w+)=(.+)$') {
		$envVars[$matches[1]] = $matches[2]
	}
}

$resourceGroup    = $envVars['RESOURCE_GROUP']
$location         = $envVars['LOCATION']
$accountName      = $envVars['COSMOSDB_ACCOUNT']
$databaseName     = $envVars['COSMOSDB_DATABASE']
$productContainer = $envVars['PRODUCTS_CONTAINER']
$ordersContainer  = $envVars['ORDERS_CONTAINER']

# Create CosmosDB account (SQL API)
az cosmosdb create --name $accountName --resource-group $resourceGroup --locations regionName=$location failoverPriority=0 isZoneRedundant=False --kind GlobalDocumentDB

# Create SQL API database
az cosmosdb sql database create --account-name $accountName --name $databaseName --resource-group $resourceGroup

# Create SQL API container for products
az cosmosdb sql container create --account-name $accountName --database-name $databaseName --name $productContainer --resource-group $resourceGroup --partition-key-path "/id" --throughput 400

# Create SQL API container for orders
az cosmosdb sql container create --account-name $accountName --database-name $databaseName --name $ordersContainer --resource-group $resourceGroup --partition-key-path "/id" --throughput 400

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
$resourceGroup = $envVars['RESOURCE_GROUP']
$location = $envVars['LOCATION']
$namespaceName = $envVars['SERVICEBUS_NAMESPACE']
$queueName = $envVars['SERVICEBUS_QUEUE']

# Create Service Bus namespace
az servicebus namespace create --resource-group $resourceGroup --name $namespaceName --location $location --sku Standard

# Create Service Bus queue
az servicebus queue create --resource-group $resourceGroup --namespace-name $namespaceName --name $queueName

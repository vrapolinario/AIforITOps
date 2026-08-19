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
$foundryResourceName = $envVars['FOUNDRY_RESOURCE_NAME']
$foundryModelDeploymentName = $envVars['FOUNDRY_MODEL_DEPLOYMENT_NAME']

Write-Host "Querying Azure resources in resource group: $resourceGroup..."

# Query CosmosDB (SQL API)
$cosmosAccount = $(az cosmosdb list --resource-group $resourceGroup --query "[0].name" -o tsv 2>$null)
$cosmosConnStr = $(az cosmosdb keys list --name $cosmosAccount --resource-group $resourceGroup --type connection-strings --query "connectionStrings[?contains(connectionString, 'AccountEndpoint')].connectionString | [0]" -o tsv 2>$null)

# Query Service Bus
$serviceBusNamespace = $(az servicebus namespace list --resource-group $resourceGroup --query "[0].name" -o tsv 2>$null)
$serviceBusConnStr = $(az servicebus namespace authorization-rule keys list --resource-group $resourceGroup --namespace-name $serviceBusNamespace --name "RootManageSharedAccessKey" --query "primaryConnectionString" -o tsv 2>$null)

# Query Key Vault
$keyVaultName = az keyvault list --resource-group $resourceGroup --query "[0].name" -o tsv

# Query Microsoft Foundry inference endpoint
$foundryEndpoint = az cognitiveservices account show --name $foundryResourceName --resource-group $resourceGroup --query "properties.endpoint" -o tsv

# Query API key
$foundryApiKey = az cognitiveservices account keys list --name $foundryResourceName --resource-group $resourceGroup --query "key1" -o tsv

Write-Host "Uploading secrets to Key Vault: $keyVaultName"

az keyvault secret set --vault-name $keyVaultName --name "CosmosDBConnectionString" --value "$cosmosConnStr" >$null 2>$null
az keyvault secret set --vault-name $keyVaultName --name "ServiceBusConnectionString" --value "$serviceBusConnStr" >$null 2>$null
az keyvault secret set --vault-name $keyVaultName --name "FoundryApiKey" --value "$foundryApiKey" >$null 2>$null
az keyvault secret set --vault-name $keyVaultName --name "FoundryEndpoint" --value "$foundryEndpoint" >$null 2>$null
az keyvault secret set --vault-name $keyVaultName --name "FoundryModelDeployment" --value "$foundryModelDeploymentName" >$null 2>$null

Write-Host "Secrets uploaded successfully."
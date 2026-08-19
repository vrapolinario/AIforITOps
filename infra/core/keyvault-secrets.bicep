@description('Name of the Key Vault')
param keyVaultName string

@description('CosmosDB connection string')
@secure()
param cosmosDbConnectionString string

@description('Service Bus connection string')
@secure()
param serviceBusConnectionString string

@description('Microsoft Foundry inference endpoint')
param foundryEndpoint string

@description('Microsoft Foundry API key')
@secure()
param foundryApiKey string

@description('Microsoft Foundry model deployment name')
param foundryModelDeploymentName string

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource cosmosDbSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'cosmosdb-connectionstring'
  properties: {
    value: cosmosDbConnectionString
  }
}

resource serviceBusSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'servicebus-connectionstring'
  properties: {
    value: serviceBusConnectionString
  }
}

resource foundryEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'foundry-endpoint'
  properties: {
    value: foundryEndpoint
  }
}

resource foundryApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'foundry-api-key'
  properties: {
    value: foundryApiKey
  }
}

resource foundryModelDeploymentSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'foundry-model-deployment'
  properties: {
    value: foundryModelDeploymentName
  }
}

output cosmosDbSecretName string = cosmosDbSecret.name
output serviceBusSecretName string = serviceBusSecret.name
output foundryEndpointSecretName string = foundryEndpointSecret.name
output foundryApiKeySecretName string = foundryApiKeySecret.name
output foundryModelDeploymentSecretName string = foundryModelDeploymentSecret.name

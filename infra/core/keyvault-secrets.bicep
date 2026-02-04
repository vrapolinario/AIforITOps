@description('Name of the Key Vault')
param keyVaultName string

@description('CosmosDB connection string')
@secure()
param cosmosDbConnectionString string

@description('Service Bus connection string')
@secure()
param serviceBusConnectionString string

@description('OpenAI endpoint')
param openAiEndpoint string

@description('OpenAI API key')
@secure()
param openAiKey string

@description('OpenAI deployment name')
param openAiDeploymentName string

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

resource openAiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-endpoint'
  properties: {
    value: openAiEndpoint
  }
}

resource openAiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-key'
  properties: {
    value: openAiKey
  }
}

resource openAiDeploymentSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-deployment'
  properties: {
    value: openAiDeploymentName
  }
}

output cosmosDbSecretName string = cosmosDbSecret.name
output serviceBusSecretName string = serviceBusSecret.name
output openAiEndpointSecretName string = openAiEndpointSecret.name
output openAiKeySecretName string = openAiKeySecret.name
output openAiDeploymentSecretName string = openAiDeploymentSecret.name

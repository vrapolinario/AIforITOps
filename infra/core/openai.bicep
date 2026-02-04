@description('Name of the Azure OpenAI resource')
param name string

@description('Location for the Azure OpenAI resource')
param location string = resourceGroup().location

@description('Tags for the Azure OpenAI resource')
param tags object = {}

@description('Name of the OpenAI deployment')
param deploymentName string

@description('Name of the OpenAI model')
param modelName string

@description('Version of the OpenAI model')
param modelVersion string

@description('SKU name for the OpenAI resource')
param skuName string = 'S0'

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAiAccount
  name: deploymentName
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output id string = openAiAccount.id
output name string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
output key string = openAiAccount.listKeys().key1

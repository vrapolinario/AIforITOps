@description('Name of the Microsoft Foundry resource')
param name string

@description('Location for the Microsoft Foundry resource')
param location string = resourceGroup().location

@description('Tags for the Microsoft Foundry resource')
param tags object = {}

@description('Name of the default Foundry project')
param projectName string

@description('Name of the model deployment')
param deploymentName string

@description('Name of the model')
param modelName string

@description('Version of the model')
param modelVersion string

@description('SKU name for the Foundry resource')
param skuName string = 'S0'

@description('SKU name for the model deployment')
param deploymentSkuName string = 'GlobalStandard'

@description('Capacity for the model deployment')
param deploymentCapacity int = 10

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: skuName
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundryAccount
  name: projectName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundryAccount
  name: deploymentName
  sku: {
    name: deploymentSkuName
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'foundry-diagnostics'
  scope: foundryAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output id string = foundryAccount.id
output name string = foundryAccount.name
output inferenceEndpoint string = foundryAccount.properties.endpoint
output projectId string = project.id
output projectName string = project.name
output projectEndpoint string = 'https://${name}.services.ai.azure.com/api/projects/${projectName}'
@secure()
output key string = foundryAccount.listKeys().key1

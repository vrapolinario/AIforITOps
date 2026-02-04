@description('Name of the container registry')
param name string

@description('Location for the container registry')
param location string = resourceGroup().location

@description('Tags for the container registry')
param tags object = {}

@description('Principal ID to grant AcrPush role (for build tasks)')
param principalId string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

output id string = containerRegistry.id
output name string = containerRegistry.name
output loginServer string = containerRegistry.properties.loginServer

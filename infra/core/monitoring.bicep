@description('Name of the Log Analytics workspace')
param name string

@description('Location for the Log Analytics workspace')
param location string = resourceGroup().location

@description('Tags for the Log Analytics workspace')
param tags object = {}

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

output id string = workspace.id
output name string = workspace.name

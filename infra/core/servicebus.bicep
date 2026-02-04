@description('Name of the Service Bus namespace')
param namespaceName string

@description('Location for the Service Bus')
param location string = resourceGroup().location

@description('Tags for the Service Bus')
param tags object = {}

@description('Name of the queue')
param queueName string

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = {
  name: namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = {
  parent: serviceBusNamespace
  name: queueName
  properties: {
    lockDuration: 'PT5M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    maxDeliveryCount: 10
  }
}

output id string = serviceBusNamespace.id
output namespaceName string = serviceBusNamespace.name
output endpoint string = 'https://${serviceBusNamespace.name}.servicebus.windows.net'
output connectionString string = listKeys('${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey', serviceBusNamespace.apiVersion).primaryConnectionString

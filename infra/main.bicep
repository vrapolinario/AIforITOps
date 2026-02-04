targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Location for OpenAI resources (may differ from primary location)')
param openAiLocation string = 'westus'

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Name of the user-assigned managed identity')
param managedIdentityName string = ''

@description('Name of the Azure Container Registry')
param containerRegistryName string = ''

@description('Name of the AKS cluster')
param aksClusterName string = ''

@description('Name of the CosmosDB account')
param cosmosDbAccountName string = ''

@description('Name of the Service Bus namespace')
param serviceBusNamespaceName string = ''

@description('Name of the Key Vault')
param keyVaultName string = ''

@description('Name of the OpenAI resource')
param openAiResourceName string = ''

@description('OpenAI deployment name')
param openAiDeploymentName string = 'gpt-4o'

@description('OpenAI model name')
param openAiModelName string = 'gpt-4o'

@description('OpenAI model version')
param openAiModelVersion string = '2024-11-20'

@description('CosmosDB database name')
param cosmosDbDatabaseName string = 'productsdb'

@description('CosmosDB products container name')
param cosmosDbProductsContainerName string = 'productscontainer'

@description('CosmosDB orders container name')
param cosmosDbOrdersContainerName string = 'orderscontainer'

@description('Service Bus queue name')
param serviceBusQueueName string = 'productsqueue'

@description('Kubernetes version for AKS (leave empty for latest stable)')
param aksKubernetesVersion string = ''

@description('VM size for AKS node pools')
param aksNodePoolVmSize string = 'Standard_D2s_v3'

@description('Number of nodes in AKS system node pool')
param aksSystemNodeCount int = 2

@description('Number of nodes in AKS user node pool')
param aksUserNodeCount int = 2

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Tags that should be applied to all resources
var tags = {
  'azd-env-name': environmentName
  'project': 'ai-for-itops'
}

// Generate unique names for resources
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// User-assigned managed identity for AKS
module managedIdentity './core/identity.bicep' = {
  name: 'managed-identity'
  scope: rg
  params: {
    name: !empty(managedIdentityName) ? managedIdentityName : '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    location: location
    tags: tags
  }
}

// Azure Container Registry
module containerRegistry './core/acr.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    principalId: managedIdentity.outputs.principalId
  }
}

// Azure Kubernetes Service
module aksCluster './core/aks.bicep' = {
  name: 'aks-cluster'
  scope: rg
  params: {
    name: !empty(aksClusterName) ? aksClusterName : '${abbrs.containerServiceManagedClusters}${resourceToken}'
    location: location
    tags: tags
    managedIdentityId: managedIdentity.outputs.id
    kubernetesVersion: aksKubernetesVersion
    vmSize: aksNodePoolVmSize
    systemNodeCount: aksSystemNodeCount
    userNodeCount: aksUserNodeCount
  }
}

// CosmosDB account
module cosmosDb './core/cosmosdb.bicep' = {
  name: 'cosmos-db'
  scope: rg
  params: {
    accountName: !empty(cosmosDbAccountName) ? cosmosDbAccountName : '${abbrs.documentDBDatabaseAccounts}${resourceToken}'
    location: location
    tags: tags
    databaseName: cosmosDbDatabaseName
    productsContainerName: cosmosDbProductsContainerName
    ordersContainerName: cosmosDbOrdersContainerName
  }
}

// Service Bus
module serviceBus './core/servicebus.bicep' = {
  name: 'service-bus'
  scope: rg
  params: {
    namespaceName: !empty(serviceBusNamespaceName) ? serviceBusNamespaceName : '${abbrs.serviceBusNamespaces}${resourceToken}'
    location: location
    tags: tags
    queueName: serviceBusQueueName
  }
}

// Key Vault
module keyVault './core/keyvault.bicep' = {
  name: 'key-vault'
  scope: rg
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
    managedIdentityPrincipalId: managedIdentity.outputs.principalId
  }
}

// Azure OpenAI
module openAi './core/openai.bicep' = {
  name: 'open-ai'
  scope: rg
  params: {
    name: !empty(openAiResourceName) ? openAiResourceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: openAiLocation
    tags: tags
    deploymentName: openAiDeploymentName
    modelName: openAiModelName
    modelVersion: openAiModelVersion
  }
}

// Store secrets in Key Vault
module keyVaultSecrets './core/keyvault-secrets.bicep' = {
  name: 'key-vault-secrets'
  scope: rg
  params: {
    keyVaultName: keyVault.outputs.name
    cosmosDbConnectionString: cosmosDb.outputs.connectionString
    serviceBusConnectionString: serviceBus.outputs.connectionString
    openAiEndpoint: openAi.outputs.endpoint
    openAiKey: openAi.outputs.key
    openAiDeploymentName: openAiDeploymentName
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

output AZURE_AKS_CLUSTER_NAME string = aksCluster.outputs.name
output AZURE_MANAGED_IDENTITY_CLIENT_ID string = managedIdentity.outputs.clientId
output AZURE_MANAGED_IDENTITY_ID string = managedIdentity.outputs.id

output AZURE_COSMOSDB_ACCOUNT_NAME string = cosmosDb.outputs.accountName
output AZURE_COSMOSDB_DATABASE_NAME string = cosmosDbDatabaseName
output AZURE_COSMOSDB_PRODUCTS_CONTAINER string = cosmosDbProductsContainerName
output AZURE_COSMOSDB_ORDERS_CONTAINER string = cosmosDbOrdersContainerName

output AZURE_SERVICEBUS_NAMESPACE string = serviceBus.outputs.namespaceName
output AZURE_SERVICEBUS_QUEUE string = serviceBusQueueName

output AZURE_KEY_VAULT_NAME string = keyVault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint

output AZURE_OPENAI_RESOURCE_NAME string = openAi.outputs.name
output AZURE_OPENAI_ENDPOINT string = openAi.outputs.endpoint
output AZURE_OPENAI_DEPLOYMENT_NAME string = openAiDeploymentName

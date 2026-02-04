@description('Name of the AKS cluster')
param name string

@description('Location for the AKS cluster')
param location string = resourceGroup().location

@description('Tags for the AKS cluster')
param tags object = {}

@description('Resource ID of the managed identity')
param managedIdentityId string

@description('Kubernetes version (leave empty for latest stable)')
param kubernetesVersion string = ''

@description('VM size for the node pools')
param vmSize string = 'Standard_D2s_v3'

@description('Number of nodes in the system node pool')
param systemNodeCount int = 2

@description('Number of nodes in the user node pool')
param userNodeCount int = 2

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-01-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    kubernetesVersion: !empty(kubernetesVersion) ? kubernetesVersion : null
    dnsPrefix: '${name}-dns'
    agentPoolProfiles: [
      {
        name: 'system'
        count: systemNodeCount
        vmSize: vmSize
        mode: 'System'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
      }
      {
        name: 'userpool'
        count: userNodeCount
        vmSize: vmSize
        mode: 'User'
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
  }
}

output id string = aksCluster.id
output name string = aksCluster.name
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId

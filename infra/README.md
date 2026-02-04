# Infrastructure as Code (Bicep)

This directory contains all the Infrastructure as Code (IaC) for the AI for IT/Ops project using Azure Bicep.

## Structure

```
infra/
├── main.bicep              # Main orchestrator - deploys all resources
├── main.parameters.json    # Parameter mappings from azd environment
├── abbreviations.json      # Resource naming conventions
├── core/                   # Bicep modules for each service
│   ├── identity.bicep      # Managed identity for AKS
│   ├── acr.bicep          # Azure Container Registry
│   ├── aks.bicep          # Azure Kubernetes Service
│   ├── cosmosdb.bicep     # Cosmos DB with containers
│   ├── servicebus.bicep   # Service Bus with queue
│   ├── keyvault.bicep     # Key Vault with RBAC
│   ├── keyvault-secrets.bicep  # Secrets storage
│   └── openai.bicep       # Azure OpenAI with deployment
└── hooks/                 # Deployment lifecycle hooks
    ├── postprovision.ps1  # Configure after infrastructure
    ├── postprovision.sh
    ├── postdeploy.ps1     # Deploy to Kubernetes
    └── postdeploy.sh
```

## How It Works

1. **`azd provision`** deploys `main.bicep` which:
   - Creates resource group
   - Deploys all core modules
   - Configures RBAC and permissions
   - Stores secrets in Key Vault
   - Returns outputs to azd environment

2. **`postprovision` hook** then:
   - Gets AKS credentials
   - Creates Kubernetes namespace
   - Updates K8s manifests with actual values

3. **`azd deploy`** builds and pushes images, then:
   - Updates K8s deployments with new images

4. **`postdeploy` hook** then:
   - Applies all Kubernetes manifests
   - Displays service URLs

## Key Features

### Security
- RBAC-based Key Vault access
- Managed identities (no credentials in code)
- Workload identity for AKS pods
- Secrets stored in Key Vault
- CSI Secret Store Driver integration

### Modularity
- Each Azure service in its own module
- Easy to modify or extend
- Reusable components

### Resource Naming
- Consistent naming via abbreviations
- Environment-based unique suffixes
- Follows Azure naming best practices

## Outputs

The main.bicep file outputs these values to azd environment:

- `AZURE_LOCATION` - Deployment region
- `AZURE_TENANT_ID` - Azure AD tenant
- `AZURE_RESOURCE_GROUP` - Resource group name
- `AZURE_CONTAINER_REGISTRY_NAME` - ACR name
- `AZURE_CONTAINER_REGISTRY_ENDPOINT` - ACR login server
- `AZURE_AKS_CLUSTER_NAME` - AKS cluster name
- `AZURE_MANAGED_IDENTITY_CLIENT_ID` - Identity for AKS
- `AZURE_COSMOSDB_ACCOUNT_NAME` - Cosmos DB account
- `AZURE_SERVICEBUS_NAMESPACE` - Service Bus namespace
- `AZURE_KEY_VAULT_NAME` - Key Vault name
- `AZURE_OPENAI_RESOURCE_NAME` - OpenAI resource
- `AZURE_OPENAI_ENDPOINT` - OpenAI endpoint
- And more...

## Customization

### Change Resource Names

Set environment variables before deployment:

```bash
azd env set AZURE_CONTAINER_REGISTRY_NAME myacr123
azd env set AZURE_AKS_CLUSTER_NAME myaks
azd env set AZURE_COSMOSDB_ACCOUNT_NAME mycosmosdb
```

### Configure AKS Cluster

Customize AKS configuration via environment variables:

```bash
# Set VM size (important for regional availability)
azd env set AZURE_AKS_NODE_POOL_VM_SIZE Standard_D4s_v3

# Set node count
azd env set AZURE_AKS_NODE_POOL_NODE_COUNT 5

# Set Kubernetes version (optional, defaults to latest stable)
azd env set AZURE_AKS_KUBERNETES_VERSION 1.28.9

# Check available VM sizes for your region
az vm list-skus --location <your-location> --size Standard_D --output table
```

**Default values:**
- VM Size: `Standard_D2s_v3`
- Node Count: `3`
- Kubernetes Version: Latest stable (auto-selected by Azure)

### Modify Resources

Edit the corresponding module file in `core/`:

- Want different AKS node size? → Set `AZURE_AKS_NODE_POOL_VM_SIZE` or edit `core/aks.bicep`
- Need different Cosmos DB consistency? → Edit `core/cosmosdb.bicep`
- Want different OpenAI model? → Edit parameters in `main.bicep`

### Add New Resources

1. Create a new module in `core/`
2. Reference it in `main.bicep`
3. Add outputs as needed
4. Run `azd provision` to update

## Testing Locally

```bash
# Validate Bicep syntax
az bicep build --file main.bicep

# What-if deployment (preview changes)
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters main.parameters.json \
  --what-if

# Deploy manually (outside azd)
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters main.parameters.json
```

## Best Practices

✅ Keep modules focused and single-purpose  
✅ Use descriptive parameter names  
✅ Document all parameters  
✅ Use outputs for inter-module communication  
✅ Follow Azure naming conventions  
✅ Use RBAC over access keys  
✅ Enable managed identities  
✅ Tag all resources  

## Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Naming Conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

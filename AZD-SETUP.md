# Azure Developer CLI (azd) Setup Guide

Before diving into the workshop, make sure you have completed the implementation of the sample e-commerce application. This project has been configured to use Azure Developer CLI (azd) for simplified deployment and management.

## Prerequisites

1. **Install Azure Developer CLI**:

```powershell
# Windows (using winget)
winget install microsoft.azd

# Or using PowerShell
powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
```

2. **Verify installation**:

```bash
azd version
```

Use `winget upgrade Microsoft.Azd` if the installed version is earlier than 1.25.0. Install the Microsoft Foundry extension with the required user agent:

```powershell
$env:AZURE_DEV_USER_AGENT="microsoft_foundry_skill"; azd extension install microsoft.foundry
```

3. **Clone the repository if you haven't already:**

```bash
git clone https://github.com/microsoft/AIforITOps.git
cd AIforITOps
# macOS/Linux only: make azd hook scripts executable
chmod +x infra/hooks/*.sh
```

4. **Install required tools** (if not already installed):
   - Azure CLI: `winget install Microsoft.AzureCLI`
   - kubectl: `az aks install-cli`

5. **Login to Azure**:

```bash
# Login to Azure with azd
azd auth login
# Login with Azure CLI
az login
```

## 1. Initialize Your Environment

```bash
# Create a new environment (use a descriptive name like "dev", "test", "workshop")
# The environment name will be used as the Resource Group name in Azure, so choose something unique to avoid conflicts
azd env new dev
```

**Note**: You'll be prompted for Azure subscription and location when you run `azd up` or `azd provision`.

### Optional: Pre-configure Environment Variables

Before deploying, it is recommended that you set environment variables to customize your deployment:

```bash
# Required (will be prompted if not set)
azd env set AZURE_LOCATION westus2  # Azure region for resources, replace with your preferred location
azd env set AZURE_SUBSCRIPTION_ID <guid>  # Your Azure subscription ID

# Optional - Custom resource names
azd env set AZURE_MANAGED_IDENTITY_NAME myidentity
azd env set AZURE_CONTAINER_REGISTRY_NAME myacr123
azd env set AZURE_AKS_CLUSTER_NAME myakscluster
azd env set AZURE_COSMOSDB_ACCOUNT_NAME mycosmosdb
azd env set AZURE_SERVICEBUS_NAMESPACE myservicebus123
azd env set AZURE_KEY_VAULT_NAME mykv123
azd env set AZURE_FOUNDRY_RESOURCE_NAME myfoundry

# Optional - AKS Configuration
azd env set AZURE_AKS_NODE_POOL_VM_SIZE Standard_D2s_v3      # Default
azd env set AZURE_AKS_NODE_POOL_NODE_COUNT 2                  # Default
azd env set AZURE_AKS_KUBERNETES_VERSION ""                   # Leave empty for latest stable

# Optional - Microsoft Foundry project and model configuration
azd env set AZURE_FOUNDRY_LOCATION westus
azd env set AZURE_FOUNDRY_PROJECT_NAME aifor-itops
azd env set AZURE_FOUNDRY_MODEL_DEPLOYMENT_NAME gpt-4o
azd env set AZURE_FOUNDRY_MODEL_NAME gpt-4o
azd env set AZURE_FOUNDRY_MODEL_VERSION 2024-11-20
azd env set AZURE_FOUNDRY_MODEL_SKU_NAME GlobalStandard
azd env set AZURE_FOUNDRY_MODEL_CAPACITY 10

# View all configured values
azd env get-values
```

### 2. Deploy Everything

```bash
# One command to provision infrastructure and deploy applications
azd up
```

This single command will:

- Create all Azure resources, including Microsoft Foundry, its default project and model deployment, and Log Analytics diagnostics
- Build and push container images to ACR
- Configure Kubernetes manifests with resource details
- Deploy applications to AKS

### 3. Access Your Application

After deployment completes, retrieve the application URLs:

```bash
# Get both URLs
azd env get-value STOREFRONT_URL
azd env get-value ADMINSITE_URL
```

## Cleanup

If for any reason you need to tear down the environment and delete all resources, run:

```bash
# Delete all Azure resources for current environment
azd down

# Force delete and purge all lingering resource names
azd down --force --purge
```

## AZD Implementation Details

To check the implementation details of this deployment using Azure Developer CLI, please refer to the [AZD-IMPLEMENTATION.md](./AZD-IMPLEMENTATION.md) file.

## Workshop

Note: Make sure the environment is up and running before you start this section.

Once the environment has been deployed and you were able to open and use the application, we can start exploring some IT/Ops related tasks. The workshop is divided into four exercises and you can find the workshop guide in the [Workshop folder's ReadMe.md](./Workshop/ReadMe.md) file.

# Azure Developer CLI Setup - Implementation Summary

## ✅ What Was Created

### 1. Core Configuration Files

- **[azure.yaml](./azure.yaml)** - Main azd project definition
  - Defines 3 services: StoreFront, AdminSite, ProductWorker
  - Configures Docker builds and Kubernetes deployments
  - Sets up deployment hooks

- **[.gitignore](./.gitignore)** - Updated to exclude azd files
  - Ignores `.azure/` directory (contains secrets)
  - Ignores `*.final.yaml` files (generated)

### 2. Infrastructure as Code (Bicep)

#### Main Files
- **[infra/main.bicep](./infra/main.bicep)** - Orchestrates all resources
- **[infra/main.parameters.json](./infra/main.parameters.json)** - Parameter mappings
- **[infra/abbreviations.json](./infra/abbreviations.json)** - Naming conventions

#### Module Files (infra/core/)
- **identity.bicep** - User-assigned managed identity for AKS
- **acr.bicep** - Azure Container Registry with role assignments
- **aks.bicep** - Azure Kubernetes Service with workload identity
- **cosmosdb.bicep** - CosmosDB with databases and containers
- **servicebus.bicep** - Service Bus namespace and queue
- **keyvault.bicep** - Key Vault with RBAC roles
- **keyvault-secrets.bicep** - Secrets storage in Key Vault
- **openai.bicep** - Azure OpenAI with model deployment

### 3. Deployment Hooks

Located in `infra/hooks/`:

- **postprovision.ps1** / **postprovision.sh**
  - Runs after `azd provision`
  - Gets AKS credentials
  - Creates Kubernetes namespace
  - Updates SecretProviderClass manifests with actual values

- **postdeploy.ps1** / **postdeploy.sh**
  - Runs after `azd deploy`
  - Applies Kubernetes ConfigMaps
  - Applies SecretProviderClass resources
  - Deploys applications to AKS
  - Displays service URLs

### 4. Environment Configuration

- **[.azure/](./.azure/)** - Environment-specific settings
  - `.gitignore` - Ensures secrets aren't committed
  - `README.md` - Explains directory purpose

### 5. Documentation

- **[AZD-SETUP.md](./AZD-SETUP.md)** - Comprehensive setup guide
  - Installation instructions
  - Step-by-step deployment
  - Environment management
  - Troubleshooting tips
  - Comparison with old approach

### 6. Updated Kubernetes Manifests

Updated all SecretProviderClass files to use variable placeholders:
- `k8s/keyvault-cosmosdb-spc.yaml`
- `k8s/keyvault-servicebus-spc.yaml`
- `k8s/keyvault-openai-spc.yaml`
- `k8s/keyvault-openai-key-spc.yaml`
- `k8s/keyvault-openai-deployment-spc.yaml`

## 🎯 How It Works

### Deployment Flow

1. **`azd up`** (or individual commands):
   
2. **Provision Phase** (`azd provision`):
   - Deploys `infra/main.bicep` to Azure
   - Creates all infrastructure resources
   - Stores outputs in environment variables
   - Runs `postprovision` hook:
     - Gets AKS credentials
     - Generates `.final.yaml` files with actual values

3. **Package Phase** (`azd package`):
   - Builds Docker images for each service
   - Pushes images to Azure Container Registry

4. **Deploy Phase** (`azd deploy`):
   - Updates Kubernetes deployments with new image tags
   - Runs `postdeploy` hook:
     - Applies all Kubernetes manifests
     - Displays service URLs

## � Comparison with PowerShell Scripts

### Resource Mapping

| PowerShell Script | Bicep Module | Status |
|------------------|--------------|---------|
| `create-acr-images.ps1` | `core/acr.bicep` + azd package | ✅ Automated |
| `create-aks.ps1` | `core/aks.bicep` + `core/identity.bicep` | ✅ Automated |
| `create-cosmosdb.ps1` | `core/cosmosdb.bicep` | ✅ Automated |
| `create-servicebus.ps1` | `core/servicebus.bicep` | ✅ Automated |
| `create-keyvault.ps1` | `core/keyvault.bicep` | ✅ Automated |
| `deploy-openai.ps1` | `core/openai.bicep` | ✅ Automated |
| `upload-secrets-to-keyvault.ps1` | `core/keyvault-secrets.bicep` | ✅ Automated |
| `update-secretstoreyaml.ps1` | `postprovision` hook | ✅ Automated |
| `set-customlabel.ps1` | Integrated in `core/aks.bicep` | ✅ Automated |
| kubectl commands | `postdeploy` hook | ✅ Automated |

### PowerShell Scripts vs azd

| Task | PowerShell Scripts | azd |
|------|-------------------|-----|
| Configuration | Edit `scripts/env.conf` | `azd env new <name>` |
| Full deployment | Run 7+ scripts in sequence | `azd up` |
| Resource naming | Manual, must ensure uniqueness | Auto-generated, unique |
| Multiple environments | Edit env.conf each time | `azd env new <env>` |
| State tracking | Manual | Automatic |
| CI/CD setup | Manual pipeline creation | `azd pipeline config` |

### What azd Does Automatically

✅ Creates all Azure resources in correct order  
✅ Manages dependencies between resources  
✅ Assigns proper RBAC roles  
✅ Stores connection strings as secrets  
✅ Configures AKS with workload identity  
✅ Builds and pushes Docker images  
✅ Updates Kubernetes manifests  
✅ Deploys applications to AKS  
✅ Tracks environment state  
✅ Supports multiple environments (dev/test/prod)  

## 📊 Key Benefits

1. **Single Command Deployment**: `azd up` replaces 10+ manual steps
2. **Environment Isolation**: Separate dev/test/prod environments
3. **Infrastructure as Code**: All resources defined in version-controlled Bicep
4. **Idempotent**: Safe to run multiple times
5. **CI/CD Ready**: Easy GitHub Actions or Azure DevOps integration
6. **Secure by Default**: RBAC, managed identities, Key Vault integration
7. **Reproducible**: Same deployment every time

## 🚀 Next Steps

1. **Install azd**: `winget install microsoft.azd`
2. **Read the guide**: [AZD-SETUP.md](./AZD-SETUP.md)
3. **Deploy**: `azd up`
4. **Set up CI/CD**: `azd pipeline config`

## 📝 Notes

- The original PowerShell scripts in `scripts/` are preserved for reference
- The original `README.md` explains the manual process
- All azd deployments create resources with consistent naming using the environment name
- Secrets are automatically rotated between the Key Vault and AKS via the CSI driver

## 🆘 Support

- **azd Issues**: https://github.com/Azure/azure-dev/issues
- **Project Issues**: Use GitHub Issues in this repository
- **Documentation**: [Microsoft Learn - Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

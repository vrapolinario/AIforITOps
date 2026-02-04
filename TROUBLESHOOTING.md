# Common Deployment Errors and Solutions

This guide covers the most common errors encountered during `azd provision` or `azd up` and how to resolve them.

## Error: VM Size Not Available

### Symptoms
```
BadRequest: The VM size of Standard_DS2_v2 is not allowed in your subscription in location 'westus2'
```

### Cause
The default VM size is not available in your Azure region or subscription.

### Solution
```bash
# Option 1: Check and set an available VM size
az vm list-skus --location westus2 --size Standard_D --output table | grep -i available

# Set a commonly available size
azd env set AZURE_AKS_NODE_POOL_VM_SIZE Standard_D2s_v3

# Retry
azd provision
```

**Common available VM sizes:**
- `Standard_D2s_v3` (default, 2 vCPU, 8 GB RAM)
- `Standard_D4s_v3` (4 vCPU, 16 GB RAM)
- `Standard_B4ms` (4 vCPU, 16 GB RAM, cost-effective)
- `Standard_D2s_v4` (newer generation)

---

## Error: Resource Provisioning Not Terminal

### Symptoms
```
RequestConflict: Cannot modify resource...provisioning state is not terminal
```

### Cause
A previous deployment operation is still in progress for that resource.

### Solution
**Wait 2-5 minutes** for Azure to complete the previous operation, then retry:

```bash
azd provision
```

If the error persists after 10 minutes, check the resource in Azure Portal to see its provisioning state.

---

## Error: Kubernetes Version Not Supported

### Symptoms
```
K8sVersionNotSupported: Managed cluster is on version 1.29.0, which is only available for Long-Term Support (LTS)
```

### Cause
The specified Kubernetes version requires LTS tier or is not available in your region.

### Solution
**Use the default (empty) setting** to let Azure select the latest stable version:

```bash
# Don't set the version - let Azure choose
# Or explicitly clear it:
azd env set AZURE_AKS_KUBERNETES_VERSION ""

azd provision
```

**If you need a specific version:**
```bash
# Check available versions for your region
az aks get-versions --location eastus --output table

# Set a supported version (not LTS-required)
azd env set AZURE_AKS_KUBERNETES_VERSION 1.28.9

azd provision
```

---

## Error: Quota Exceeded

### Symptoms
```
QuotaExceeded: Operation could not be completed as it results in exceeding approved standardDSv2Family Cores quota
```

### Cause
Your subscription has insufficient quota for the requested resources.

### Solution

**Option 1: Use smaller VM size**
```bash
azd env set AZURE_AKS_NODE_POOL_VM_SIZE Standard_B4ms
azd env set AZURE_AKS_NODE_POOL_NODE_COUNT 2
azd provision
```

**Option 2: Request quota increase**
1. Go to Azure Portal → Subscriptions → Usage + quotas
2. Search for the VM family (e.g., "DSv2")
3. Click "Request increase"
4. Wait for approval (usually 24-48 hours)

**Option 3: Use different region**
```bash
# Create new environment with different location
azd env new prod
# Select a different region when prompted (e.g., eastus instead of westus2)
azd up
```

---

## Error: Container Registry Name Already Exists

### Symptoms
```
ContainerRegistryNameNotAvailable: The container registry name 'crabc123xyz' is already in use
```

### Cause
The auto-generated ACR name conflicts with an existing registry (globally unique requirement).

### Solution
```bash
# Set a custom unique ACR name (must be globally unique, lowercase, no hyphens)
azd env set AZURE_CONTAINER_REGISTRY_NAME mycompanyacr2024

azd provision
```

---

## Error: Key Vault Name Already Exists

### Symptoms
```
VaultAlreadyExists: The vault name 'kv-abc123xyz' is already in use
```

### Cause
Key Vault names are globally unique and soft-delete preserves names for 90 days.

### Solution

**Option 1: Set custom name**
```bash
azd env set AZURE_KEY_VAULT_NAME mycompanykv2024
azd provision
```

**Option 2: Purge soft-deleted vault**
```bash
# List soft-deleted vaults
az keyvault list-deleted

# Purge the conflicting vault (if you own it)
az keyvault purge --name kv-abc123xyz --location eastus

# Retry
azd provision
```

---

## Error: OpenAI Service Not Available

### Symptoms
```
ResourceNotAvailable: The requested resource is not available in location 'eastus'
```

### Cause
Azure OpenAI is not available in all regions or requires approval.

### Solution
```bash
# Use a region where OpenAI is available
azd env set AZURE_OPENAI_LOCATION westus

azd provision
```

---

## Error: Pods Not Starting

### Symptoms
After deployment, pods are in `CrashLoopBackOff` or `ImagePullBackOff`.

### Diagnosis
```bash
# Check pod status
kubectl get pods -n ai-demo

# Check pod logs
kubectl logs <pod-name> -n ai-demo

# Check pod events
kubectl describe pod <pod-name> -n ai-demo
```

### Common Causes & Solutions

**ImagePullBackOff:**
```bash
# Verify ACR connection
az acr login --name $(azd env get-value AZURE_CONTAINER_REGISTRY_NAME)

# Check if images exist
az acr repository list --name $(azd env get-value AZURE_CONTAINER_REGISTRY_NAME)

# Re-deploy
azd deploy
```

**CrashLoopBackOff - Missing secrets:**
```bash
# Re-run post-provision hook
.\infra\hooks\postprovision.ps1

# Check SecretProviderClass
kubectl get secretproviderclass -n ai-demo

# Re-apply manifests
.\infra\hooks\postdeploy.ps1
```

---

## Error: External IP Pending Forever

### Symptoms
`kubectl get svc -n ai-demo` shows `<pending>` for EXTERNAL-IP for more than 10 minutes.

### Solution
```bash
# Check LoadBalancer service events
kubectl describe svc storefront -n ai-demo

# Common issue: subscription doesn't have permission to create public IPs
# Verify in Azure Portal: Subscriptions → Resource providers → Microsoft.Network (should be Registered)

# If needed, register the provider
az provider register --namespace Microsoft.Network

# Wait a few minutes, then check again
kubectl get svc -n ai-demo
```

---

## General Troubleshooting Steps

### 1. Check Environment Variables
```bash
azd env get-values
```

### 2. View Detailed Logs
```bash
azd up --debug
```

### 3. Check Azure Resources
```bash
az resource list --resource-group $(azd env get-value AZURE_RESOURCE_GROUP) --output table
```

### 4. Verify AKS Access
```bash
az aks get-credentials \
  --resource-group $(azd env get-value AZURE_RESOURCE_GROUP) \
  --name $(azd env get-value AZURE_AKS_CLUSTER_NAME) \
  --overwrite-existing

kubectl get nodes
```

### 5. Re-run Hooks
```powershell
# Windows
.\infra\hooks\postprovision.ps1
.\infra\hooks\postdeploy.ps1
```

```bash
# Linux/Mac
./infra/hooks/postprovision.sh
./infra/hooks/postdeploy.sh
```

---

## Still Having Issues?

1. **Clean up and retry:**
   ```bash
   azd down --force --purge
   azd up
   ```

2. **Check Azure status:** [https://status.azure.com](https://status.azure.com)

3. **Open an issue:** Use the GitHub Issues tab with:
   - Error message
   - Output from `azd env get-values`
   - Azure region
   - Output from `azd up --debug`

---

## Prevention Tips

✅ Always check VM availability before deployment  
✅ Use default settings when possible (they're tested across regions)  
✅ Keep resource names globally unique  
✅ Use separate environments for dev/test/prod  
✅ Monitor Azure quota usage regularly  
✅ Document custom configurations in your environment  

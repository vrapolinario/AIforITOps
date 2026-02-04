# Post-provision hook to configure Kubernetes manifests
Write-Host "Running post-provision hook..."

# Load environment variables from azd
$env:AZURE_KEY_VAULT_NAME = azd env get-value AZURE_KEY_VAULT_NAME
$env:AZURE_TENANT_ID = azd env get-value AZURE_TENANT_ID
$env:AZURE_MANAGED_IDENTITY_CLIENT_ID = azd env get-value AZURE_MANAGED_IDENTITY_CLIENT_ID

Write-Host "Key Vault Name: $env:AZURE_KEY_VAULT_NAME"
Write-Host "Tenant ID: $env:AZURE_TENANT_ID"
Write-Host "Managed Identity Client ID: $env:AZURE_MANAGED_IDENTITY_CLIENT_ID"

# Get AKS credentials
$aksClusterName = azd env get-value AZURE_AKS_CLUSTER_NAME
$resourceGroup = azd env get-value AZURE_RESOURCE_GROUP
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME

Write-Host "Getting AKS credentials for cluster: $aksClusterName"
az aks get-credentials --resource-group $resourceGroup --name $aksClusterName --overwrite-existing

# Attach ACR to AKS cluster
Write-Host "Attaching ACR ($acrName) to AKS cluster ($aksClusterName)..."
az aks update --name $aksClusterName --resource-group $resourceGroup --attach-acr $acrName

# Assign managed identity to the user node pool VMSS
Write-Host "Assigning managed identity to user node pool..."
$managedIdentityId = azd env get-value AZURE_MANAGED_IDENTITY_ID
$vmssResourceGroup = az aks show --resource-group $resourceGroup --name $aksClusterName --query "nodeResourceGroup" -o tsv
$vmssNodepoolName = az vmss list --resource-group $vmssResourceGroup --query "[].name" -o tsv | Select-String "userpool"

if ($vmssNodepoolName) {
    Write-Host "Found VMSS: $vmssNodepoolName in resource group: $vmssResourceGroup"
    az vmss identity assign --resource-group $vmssResourceGroup --name $vmssNodepoolName --identities $managedIdentityId
    
    Write-Host "Updating VMSS instances..."
    az vmss update-instances -g $vmssResourceGroup -n $vmssNodepoolName --instance-ids *
    Write-Host "Managed identity assigned and VMSS instances updated successfully!"
} else {
    Write-Warning "User node pool VMSS not found. Skipping managed identity assignment."
}
Write-Host ""

# Build and push container images using ACR tasks
Write-Host ""
Write-Host "Building container images using ACR tasks..."
Write-Host "This may take several minutes..."

$projectRoot = Join-Path $PSScriptRoot "..\..\"

Write-Host "Building StoreFront image..."
az acr build --registry $acrName --image storefront:latest --file "$projectRoot\StoreFront\Dockerfile" $projectRoot

Write-Host "Building AdminSite image..."
az acr build --registry $acrName --image adminsite:latest --file "$projectRoot\AdminSite\Dockerfile" $projectRoot

Write-Host "Building ProductWorker image..."
az acr build --registry $acrName --image productworker:latest --file "$projectRoot\ProductWorker\Dockerfile" $projectRoot

Write-Host "All container images built and pushed successfully!"
Write-Host ""

# Set custom label on user node pool
Write-Host "Setting workload=true label on user node pool..."
kubectl get nodes -l agentpool=userpool -o name | ForEach-Object { kubectl label $_ workload=true --overwrite }
Write-Host "Node labels applied successfully!"
Write-Host ""

# Create namespace if it doesn't exist
Write-Host "Creating namespace ai-demo..."
kubectl create namespace ai-demo --dry-run=client -o yaml | kubectl apply -f -

# Update SecretProviderClass manifests with actual values
Write-Host "Updating SecretProviderClass manifests..."

$k8sDir = Join-Path $PSScriptRoot "..\..\k8s"

# Get ACR login server
$acrLoginServer = az acr show --name $acrName --resource-group $resourceGroup --query loginServer -o tsv
Write-Host "ACR Login Server: $acrLoginServer"

# Update deployment files with ACR name
Write-Host "Updating deployment manifests with ACR name..."
$deploymentFiles = @(
    "storefront-deployment.yaml",
    "adminsite-deployment.yaml",
    "productworker-deployment.yaml"
)

foreach ($file in $deploymentFiles) {
    $sourcePath = Join-Path $k8sDir $file
    $targetPath = Join-Path $k8sDir "$($file.Replace('.yaml', '.final.yaml'))"
    
    if (Test-Path $sourcePath) {
        Write-Host "Processing $file..."
        $content = Get-Content $sourcePath -Raw
        $content = $content -replace '<your_acrname>\.azurecr\.io', $acrLoginServer
        
        Set-Content -Path $targetPath -Value $content
        Write-Host "Created $targetPath"
    }
}

# Process each SecretProviderClass file
$spcFiles = @(
    "keyvault-cosmosdb-spc.yaml",
    "keyvault-servicebus-spc.yaml",
    "keyvault-openai-spc.yaml",
    "keyvault-openai-key-spc.yaml",
    "keyvault-openai-deployment-spc.yaml"
)

foreach ($file in $spcFiles) {
    $sourcePath = Join-Path $k8sDir $file
    $targetPath = Join-Path $k8sDir "$($file.Replace('.yaml', '.final.yaml'))"
    
    if (Test-Path $sourcePath) {
        Write-Host "Processing $file..."
        $content = Get-Content $sourcePath -Raw
        $content = $content -replace '\$\{KEY_VAULT_NAME\}', $env:AZURE_KEY_VAULT_NAME
        $content = $content -replace '\$\{TENANT_ID\}', $env:AZURE_TENANT_ID
        $content = $content -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $env:AZURE_MANAGED_IDENTITY_CLIENT_ID
        
        Set-Content -Path $targetPath -Value $content
        Write-Host "Created $targetPath"
    }
}

Write-Host "Post-provision hook completed successfully!"

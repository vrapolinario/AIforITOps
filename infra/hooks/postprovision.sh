#!/bin/bash
# Post-provision hook to configure Kubernetes manifests
echo "Running post-provision hook..."

# Load environment variables from azd
export AZURE_KEY_VAULT_NAME=$(azd env get-value AZURE_KEY_VAULT_NAME)
export AZURE_TENANT_ID=$(azd env get-value AZURE_TENANT_ID)
export AZURE_MANAGED_IDENTITY_CLIENT_ID=$(azd env get-value AZURE_MANAGED_IDENTITY_CLIENT_ID)

echo "Key Vault Name: $AZURE_KEY_VAULT_NAME"
echo "Tenant ID: $AZURE_TENANT_ID"
echo "Managed Identity Client ID: $AZURE_MANAGED_IDENTITY_CLIENT_ID"

# Get AKS credentials
AKS_CLUSTER_NAME=$(azd env get-value AZURE_AKS_CLUSTER_NAME)
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP)
ACR_NAME=$(azd env get-value AZURE_CONTAINER_REGISTRY_NAME)

echo "Getting AKS credentials for cluster: $AKS_CLUSTER_NAME"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --overwrite-existing

# Attach ACR to AKS cluster
echo "Attaching ACR ($ACR_NAME) to AKS cluster ($AKS_CLUSTER_NAME)..."
az aks update --name "$AKS_CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --attach-acr "$ACR_NAME"

# Assign managed identity to the user node pool VMSS
echo "Assigning managed identity to user node pool..."
MANAGED_IDENTITY_ID=$(azd env get-value AZURE_MANAGED_IDENTITY_ID)
VMSS_RESOURCE_GROUP=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --query "nodeResourceGroup" -o tsv)
VMSS_NODEPOOL_NAME=$(az vmss list --resource-group "$VMSS_RESOURCE_GROUP" --query "[].name" -o tsv | grep userpool)

if [ -n "$VMSS_NODEPOOL_NAME" ]; then
    echo "Found VMSS: $VMSS_NODEPOOL_NAME in resource group: $VMSS_RESOURCE_GROUP"
    az vmss identity assign --resource-group "$VMSS_RESOURCE_GROUP" --name "$VMSS_NODEPOOL_NAME" --identities "$MANAGED_IDENTITY_ID"
    
    echo "Updating VMSS instances..."
    az vmss update-instances -g "$VMSS_RESOURCE_GROUP" -n "$VMSS_NODEPOOL_NAME" --instance-ids "*"
    echo "Managed identity assigned and VMSS instances updated successfully!"
else
    echo "Warning: User node pool VMSS not found. Skipping managed identity assignment."
fi
echo ""

# Build and push container images using ACR tasks
echo ""
echo "Building container images using ACR tasks..."
echo "This may take several minutes..."

PROJECT_ROOT="$(dirname "$0")/../.."

echo "Building StoreFront image..."
az acr build --registry "$ACR_NAME" --image storefront:latest --file "$PROJECT_ROOT/StoreFront/Dockerfile" "$PROJECT_ROOT"

echo "Building AdminSite image..."
az acr build --registry "$ACR_NAME" --image adminsite:latest --file "$PROJECT_ROOT/AdminSite/Dockerfile" "$PROJECT_ROOT"

echo "Building ProductWorker image..."
az acr build --registry "$ACR_NAME" --image productworker:latest --file "$PROJECT_ROOT/ProductWorker/Dockerfile" "$PROJECT_ROOT"

echo "All container images built and pushed successfully!"
echo ""

# Set custom label on user node pool
echo "Setting workload=true label on user node pool..."
kubectl get nodes -l agentpool=userpool -o name | xargs -I {} kubectl label {} workload=true --overwrite
echo "Node labels applied successfully!"
echo ""

# Create namespace if it doesn't exist
echo "Creating namespace ai-demo..."
kubectl create namespace ai-demo --dry-run=client -o yaml | kubectl apply -f -

# Update Kubernetes manifests with actual values
echo "Updating Kubernetes manifests..."

K8S_DIR="$(dirname "$0")/../../k8s"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --query loginServer -o tsv)
echo "ACR Login Server: $ACR_LOGIN_SERVER"

# Update deployment files with ACR name
echo "Updating deployment manifests with ACR name..."
DEPLOYMENT_FILES=("storefront-deployment.yaml" "adminsite-deployment.yaml" "productworker-deployment.yaml")

for file in "${DEPLOYMENT_FILES[@]}"; do
    SOURCE_PATH="$K8S_DIR/$file"
    TARGET_PATH="$K8S_DIR/${file%.yaml}.final.yaml"
    
    if [ -f "$SOURCE_PATH" ]; then
        echo "Processing $file..."
        sed "s|<your_acrname>\.azurecr\.io|$ACR_LOGIN_SERVER|g" "$SOURCE_PATH" > "$TARGET_PATH"
        echo "Created $TARGET_PATH"
    fi
done

# Update SecretProviderClass manifests
SPC_FILES=(
    "keyvault-cosmosdb-spc.yaml"
    "keyvault-servicebus-spc.yaml"
    "keyvault-openai-spc.yaml"
    "keyvault-openai-key-spc.yaml"
    "keyvault-openai-deployment-spc.yaml"
)

for file in "${SPC_FILES[@]}"; do
    SOURCE_PATH="$K8S_DIR/$file"
    TARGET_PATH="$K8S_DIR/${file%.yaml}.final.yaml"
    
    if [ -f "$SOURCE_PATH" ]; then
        echo "Processing $file..."
        sed -e "s/\${KEY_VAULT_NAME}/$AZURE_KEY_VAULT_NAME/g" \
            -e "s/\${TENANT_ID}/$AZURE_TENANT_ID/g" \
            -e "s/\${MANAGED_IDENTITY_CLIENT_ID}/$AZURE_MANAGED_IDENTITY_CLIENT_ID/g" \
            "$SOURCE_PATH" > "$TARGET_PATH"
        echo "Created $TARGET_PATH"
    fi
done

echo "Post-provision hook completed successfully!"

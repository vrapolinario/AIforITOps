
# Load variables from env.conf
$envFile = Join-Path $PSScriptRoot 'env.conf'
if (!(Test-Path $envFile)) {
	Write-Error "Environment file env.conf not found in $PSScriptRoot."
	exit 1
}
$envVars = @{}
foreach ($line in Get-Content $envFile) {
	if ($line -match '^(\w+)=(.+)$') {
		$envVars[$matches[1]] = $matches[2]
	}
}
$resourceGroup = $envVars['RESOURCE_GROUP']
$location = $envVars['LOCATION']
$keyVaultName = $envVars['KEYVAULT_NAME']
$aksName = $envVars['AKS_NAME']

# Create Key Vault
az keyvault create --name $keyVaultName --resource-group $resourceGroup --location $location

# Ensure current user has Key Vault Secrets Officer role
$currentUser = az ad signed-in-user show --query id -o tsv
if (-not $currentUser) {
    Write-Error "Could not determine current user's objectId. Please check your Azure login."
    exit 1
}
$keyVaultId = az keyvault show --name $keyVaultName --query id -o tsv
Write-Host "Assigning Key Vault Secrets Officer role to user $currentUser on Key Vault $keyVaultName..."
az role assignment create --role "Key Vault Secrets Officer" --assignee $currentUser --scope $keyVaultId

# --- Grant AKS user-assigned managed identity access to Key Vault ---
# Get the principalId of the AKS user-assigned managed identity
$identityName = "$aksName-identity"
$identityId = az identity show --resource-group $resourceGroup --name $identityName --query principalId -o tsv

# Get subscription ID
$subscriptionId = $(az account show --query id -o tsv)

# Assign Key Vault Secrets User role to AKS managed identity at Key Vault scope
$kvScope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.KeyVault/vaults/$keyVaultName"
$roleResult = az role assignment create --assignee-object-id $identityId --role "Key Vault Secrets User" --scope $kvScope --assignee-principal-type "ServicePrincipal" 2>&1
if ($LASTEXITCODE -eq 0) {
	Write-Host "Granted AKS user-assigned managed identity Key Vault Secrets User role for RBAC access."
} else {
	Write-Error "Failed to assign Key Vault Secrets User role to managed identity. Output: $roleResult"
}
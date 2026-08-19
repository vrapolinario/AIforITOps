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
$aksName = $envVars['AKS_NAME']
$keyVaultName = $envVars['KEYVAULT_NAME']
$acrName = $envVars['ACR_NAME']

# Query Azure for tenantId and subscriptionId
$azInfo = az account show --query "{tenantId:tenantId, subscriptionId:id}" -o json | ConvertFrom-Json
$tenantId = $azInfo.tenantId

# Query AKS for user-assigned managed identity client ID
$identityName = "$aksName-identity"
$managedIdentityClientId = az identity show --resource-group $resourceGroup --name $identityName --query clientId -o tsv

# Use relative paths for portability
$k8sDir = Join-Path $PSScriptRoot '..\k8s'
$cosmosdbYamlPath = Join-Path $k8sDir 'keyvault-cosmosdb-spc.yaml'
$cosmosdbYamlFinalPath = Join-Path $k8sDir 'keyvault-cosmosdb-spc.final.yaml'
$servicebusYamlPath = Join-Path $k8sDir 'keyvault-servicebus-spc.yaml'
$servicebusYamlFinalPath = Join-Path $k8sDir 'keyvault-servicebus-spc.final.yaml'
$foundryYamlPath = Join-Path $k8sDir 'keyvault-foundry-spc.yaml'
$foundryYamlFinalPath = Join-Path $k8sDir 'keyvault-foundry-spc.final.yaml'
$foundryApiKeyYamlPath = Join-Path $k8sDir 'keyvault-foundry-api-key-spc.yaml'
$foundryApiKeyYamlFinalPath = Join-Path $k8sDir 'keyvault-foundry-api-key-spc.final.yaml'
$foundryModelDeploymentYamlPath = Join-Path $k8sDir 'keyvault-foundry-model-deployment-spc.yaml'
$foundryModelDeploymentYamlFinalPath = Join-Path $k8sDir 'keyvault-foundry-model-deployment-spc.final.yaml'

# Update keyvault-cosmosdb-spc.yaml
$cosmosdbYaml = Get-Content $cosmosdbYamlPath -Raw
$cosmosdbYaml = $cosmosdbYaml -replace '\$\{KEY_VAULT_NAME\}', $keyVaultName
$cosmosdbYaml = $cosmosdbYaml -replace '\$\{TENANT_ID\}', $tenantId
$cosmosdbYaml = $cosmosdbYaml -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $managedIdentityClientId
Set-Content $cosmosdbYamlFinalPath $cosmosdbYaml

# Update keyvault-servicebus-spc.yaml
$servicebusYaml = Get-Content $servicebusYamlPath -Raw
$servicebusYaml = $servicebusYaml -replace '\$\{KEY_VAULT_NAME\}', $keyVaultName
$servicebusYaml = $servicebusYaml -replace '\$\{TENANT_ID\}', $tenantId
$servicebusYaml = $servicebusYaml -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $managedIdentityClientId
Set-Content $servicebusYamlFinalPath $servicebusYaml

# Update keyvault-foundry-spc.yaml
$foundryYaml = Get-Content $foundryYamlPath -Raw
$foundryYaml = $foundryYaml -replace '\$\{KEY_VAULT_NAME\}', $keyVaultName
$foundryYaml = $foundryYaml -replace '\$\{TENANT_ID\}', $tenantId
$foundryYaml = $foundryYaml -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $managedIdentityClientId
Set-Content $foundryYamlFinalPath $foundryYaml

# Update keyvault-foundry-api-key-spc.yaml
$foundryApiKeyYaml = Get-Content $foundryApiKeyYamlPath -Raw
$foundryApiKeyYaml = $foundryApiKeyYaml -replace '\$\{KEY_VAULT_NAME\}', $keyVaultName
$foundryApiKeyYaml = $foundryApiKeyYaml -replace '\$\{TENANT_ID\}', $tenantId
$foundryApiKeyYaml = $foundryApiKeyYaml -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $managedIdentityClientId
Set-Content $foundryApiKeyYamlFinalPath $foundryApiKeyYaml

# Update keyvault-foundry-model-deployment-spc.yaml
$foundryModelDeploymentYaml = Get-Content $foundryModelDeploymentYamlPath -Raw
$foundryModelDeploymentYaml = $foundryModelDeploymentYaml -replace '\$\{KEY_VAULT_NAME\}', $keyVaultName
$foundryModelDeploymentYaml = $foundryModelDeploymentYaml -replace '\$\{TENANT_ID\}', $tenantId
$foundryModelDeploymentYaml = $foundryModelDeploymentYaml -replace '\$\{MANAGED_IDENTITY_CLIENT_ID\}', $managedIdentityClientId
Set-Content $foundryModelDeploymentYamlFinalPath $foundryModelDeploymentYaml

Write-Host "Updated SecretProviderClass YAMLs created in k8s folder."

# Get all deployment YAML files in the k8s folder
$deploymentFiles = Get-ChildItem -Path "$PSScriptRoot/../k8s" -Filter "*-deployment.yaml"

foreach ($file in $deploymentFiles) {
	$content = Get-Content $file.FullName -Raw
	$updated = $content -replace '<your_acrname>', $acrName
	Set-Content -Path $file.FullName -Value $updated
}

Write-Host "All deployments in k8s folder have been updated with the correct container image."
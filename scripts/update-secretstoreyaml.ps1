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
$openaiYamlPath = Join-Path $k8sDir 'keyvault-openai-spc.yaml'
$openaiYamlFinalPath = Join-Path $k8sDir 'keyvault-openai-spc.final.yaml'
$openaikeyYamlPath = Join-Path $k8sDir 'keyvault-openai-key-spc.yaml'
$openaikeyYamlFinalPath = Join-Path $k8sDir 'keyvault-openai-key-spc.final.yaml'
$openaideploymentYamlPath = Join-Path $k8sDir 'keyvault-openai-deployment-spc.yaml'
$openaideploymentYamlFinalPath = Join-Path $k8sDir 'keyvault-openai-deployment-spc.final.yaml'

# Update keyvault-cosmosdb-spc.yaml
$cosmosdbYaml = Get-Content $cosmosdbYamlPath -Raw
$cosmosdbYaml = $cosmosdbYaml -replace '<YOUR_KEYVAULT_NAME>', $keyVaultName
$cosmosdbYaml = $cosmosdbYaml -replace '<YOUR_TENANT_ID>', $tenantId
$cosmosdbYaml = $cosmosdbYaml -replace '<MANAGED_IDENTITY_CLIENT_ID>', $managedIdentityClientId
Set-Content $cosmosdbYamlFinalPath $cosmosdbYaml

# Update keyvault-servicebus-spc.yaml
$servicebusYaml = Get-Content $servicebusYamlPath -Raw
$servicebusYaml = $servicebusYaml -replace '<YOUR_KEYVAULT_NAME>', $keyVaultName
$servicebusYaml = $servicebusYaml -replace '<YOUR_TENANT_ID>', $tenantId
$servicebusYaml = $servicebusYaml -replace '<MANAGED_IDENTITY_CLIENT_ID>', $managedIdentityClientId
Set-Content $servicebusYamlFinalPath $servicebusYaml

# Update keyvault-openai-spc.yaml
$openaiYaml = Get-Content $openaiYamlPath -Raw
$openaiYaml = $openaiYaml -replace '<YOUR_KEYVAULT_NAME>', $keyVaultName
$openaiYaml = $openaiYaml -replace '<YOUR_TENANT_ID>', $tenantId
$openaiYaml = $openaiYaml -replace '<MANAGED_IDENTITY_CLIENT_ID>', $managedIdentityClientId
Set-Content $openaiYamlFinalPath $openaiYaml

# Update keyvault-openai-key-spc.yaml
$openaikeyYaml = Get-Content $openaikeyYamlPath -Raw
$openaikeyYaml = $openaikeyYaml -replace '<YOUR_KEYVAULT_NAME>', $keyVaultName
$openaikeyYaml = $openaikeyYaml -replace '<YOUR_TENANT_ID>', $tenantId
$openaikeyYaml = $openaikeyYaml -replace '<MANAGED_IDENTITY_CLIENT_ID>', $managedIdentityClientId
Set-Content $openaikeyYamlFinalPath $openaikeyYaml

# Update keyvault-openai-deployment-spc.yaml
$openaideploymentYaml = Get-Content $openaideploymentYamlPath -Raw
$openaideploymentYaml = $openaideploymentYaml -replace '<YOUR_KEYVAULT_NAME>', $keyVaultName
$openaideploymentYaml = $openaideploymentYaml -replace '<YOUR_TENANT_ID>', $tenantId
$openaideploymentYaml = $openaideploymentYaml -replace '<MANAGED_IDENTITY_CLIENT_ID>', $managedIdentityClientId
Set-Content $openaideploymentYamlFinalPath $openaideploymentYaml

Write-Host "Updated SecretProviderClass YAMLs created in k8s folder."

# Get all deployment YAML files in the k8s folder
$deploymentFiles = Get-ChildItem -Path "$PSScriptRoot/../k8s" -Filter "*-deployment.yaml"

foreach ($file in $deploymentFiles) {
	$content = Get-Content $file.FullName -Raw
	$updated = $content -replace '<your_acrname>', $acrName
	Set-Content -Path $file.FullName -Value $updated
}

Write-Host "All deployments in k8s folder have been updated with the correct container image."
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

Write-Host "Updated SecretProviderClass YAMLs created in k8s folder."
# Deploy Microsoft Foundry and its model using values from env.conf

$ErrorActionPreference = 'Stop'

$envFile = Join-Path $PSScriptRoot 'env.conf'
if (!(Test-Path $envFile)) {
    Write-Error "Environment file env.conf not found."
    exit 1
}

$envVars = @{}
foreach ($line in Get-Content $envFile) {
    if ($line -match '^([A-Z0-9_]+)=(.+)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$resourceGroup = $envVars['RESOURCE_GROUP']
$location = $envVars['FOUNDRY_LOCATION']
$foundryName = $envVars['FOUNDRY_RESOURCE_NAME']
$projectName = $envVars['FOUNDRY_PROJECT_NAME']
$deploymentName = $envVars['FOUNDRY_MODEL_DEPLOYMENT_NAME']
$modelName = $envVars['FOUNDRY_MODEL_NAME']
$modelVersion = $envVars['FOUNDRY_MODEL_VERSION']
$skuName = $envVars['FOUNDRY_MODEL_SKU_NAME']
$capacity = $envVars['FOUNDRY_MODEL_CAPACITY']

az cognitiveservices account create `
    --name $foundryName `
    --resource-group $resourceGroup `
    --location $location `
    --kind AIServices `
    --sku S0 `
    --custom-domain $foundryName `
    --allow-project-management `
    --assign-identity
if ($LASTEXITCODE -ne 0) { throw "Failed to create Microsoft Foundry resource '$foundryName'." }

az cognitiveservices account project create `
    --name $foundryName `
    --resource-group $resourceGroup `
    --project-name $projectName `
    --location $location
if ($LASTEXITCODE -ne 0) { throw "Failed to create Foundry project '$projectName'." }

az cognitiveservices account deployment create `
    --resource-group $resourceGroup `
    --name $foundryName `
    --deployment-name $deploymentName `
    --model-name $modelName `
    --model-version $modelVersion `
    --model-format OpenAI `
    --sku-name $skuName `
    --sku-capacity $capacity
if ($LASTEXITCODE -ne 0) { throw "Failed to deploy model '$deploymentName'." }

Write-Host "Microsoft Foundry resource '$foundryName', project '$projectName', and model deployment '$deploymentName' are ready."
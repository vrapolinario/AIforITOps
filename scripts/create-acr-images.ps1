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
$acrName = $envVars['ACR_NAME']
$storefrontImage = $envVars['STOREFRONT_IMAGE']
$adminsiteImage = $envVars['ADMINSITE_IMAGE']
$productworkerImage = $envVars['PRODUCTWORKER_IMAGE']

# Create resource group
az group create --name $resourceGroup --location $location

# Create ACR
az acr create --resource-group $resourceGroup --name $acrName --sku Basic --location $location

# Build images in Azure Container Registry
az acr build --registry $acrName --image $storefrontImage --file ./StoreFront/Dockerfile .
az acr build --registry $acrName --image $adminsiteImage --file ./AdminSite/Dockerfile .
az acr build --registry $acrName --image $productworkerImage --file ./ProductWorker/Dockerfile .
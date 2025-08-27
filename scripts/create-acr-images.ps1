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

# Login to Azure Container Registry
az acr login --name $acrName

# Build images
docker build -t $storefrontImage -f ./StoreFront/Dockerfile .
docker build -t $adminsiteImage -f ./AdminSite/Dockerfile .
docker build -t $productworkerImage -f ./ProductWorker/Dockerfile .

# Push images
docker push $storefrontImage
docker push $adminsiteImage
docker push $productworkerImage
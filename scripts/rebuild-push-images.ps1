# This script can be used to rebuild the container images and redeploy them to the AKS cluster.
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

$acrName = $envVars['ACR_NAME']
$storefrontImage = $envVars['STOREFRONT_IMAGE']
$adminsiteImage = $envVars['ADMINSITE_IMAGE']
$productworkerImage = $envVars['PRODUCTWORKER_IMAGE']

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

#Look for the adminsite-deployment pod
$adminsitePod = kubectl get pods -n ai-demo -l app=adminsite -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $adminsitePod -n ai-demo

#Look for the storefront-deployment pod
$storefrontPod = kubectl get pods -n ai-demo -l app=storefront -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $storefrontPod -n ai-demo

#Look for the productworker pod
$productworkerPod = kubectl get pods -n ai-demo -l app=productworker -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $productworkerPod -n ai-demo
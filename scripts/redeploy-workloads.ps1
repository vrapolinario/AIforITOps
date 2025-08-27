# DO NOT RUN THIS SCRIPT DIRECTLY FROM THE SHELL.
# This script is intended to be used for troubleshooting purposes.
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
$aksName = $envVars['AKS_NAME']
$acrName = $envVars['ACR_NAME']
$registry = $envVars['REGISTRY']
$storefrontImage = $envVars['STOREFRONT_IMAGE']
$adminsiteImage = $envVars['ADMINSITE_IMAGE']
$productworkerImage = $envVars['PRODUCTWORKER_IMAGE']
$nodePoolName = $envVars['NODEPOOL_NAME']

# Build images
docker build -t $storefrontImage -f ./StoreFront/Dockerfile .
docker build -t $adminsiteImage -f ./AdminSite/Dockerfile .
docker build -t $productworkerImage -f ./ProductWorker/Dockerfile .

# Login to Azure Container Registry
az acr login --name $acrName

# Push images
docker push $storefrontImage
docker push $adminsiteImage
docker push $productworkerImage

#Delete pods running the workloads (for troubleshooting purposes)
#Look for the adminsite-deployment pod
$adminsitePod = kubectl get pods -n ai-demo -l app=adminsite -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $adminsitePod -n ai-demo

#Look for the storefront-deployment pod
$storefrontPod = kubectl get pods -n ai-demo -l app=storefront -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $storefrontPod -n ai-demo

#Look for the productworker pod
$productworkerPod = kubectl get pods -n ai-demo -l app=productworker -o jsonpath="{.items[0].metadata.name}"
kubectl delete pod $productworkerPod -n ai-demo

#Remove all Kubernetes resources if needed
kubectl delete namespace ai-demo --wait=false

#Deploy apps
kubectl create namespace ai-demo
kubectl apply -f ./k8s/cosmosdb-configmap.yaml
kubectl apply -f ./k8s/servicebus-configmap.yaml
kubectl apply -f ./k8s/keyvault-cosmosdb-spc.final.yaml
kubectl apply -f ./k8s/keyvault-servicebus-spc.final.yaml
kubectl apply -f ./k8s/storefront-deployment.yaml
kubectl apply -f ./k8s/storefront-service.yaml
kubectl apply -f ./k8s/adminsite-deployment.yaml
kubectl apply -f ./k8s/adminsite-service.yaml
kubectl apply -f ./k8s/productworker-deployment.yaml

#Troubleshoot pod on AdminSite
$adminsitePod = kubectl get pods -n ai-demo -l app=adminsite -o jsonpath="{.items[0].metadata.name}"
kubectl logs $adminsitePod -n ai-demo

#Troubleshoot pod on StoreFront
$storefrontPod = kubectl get pods -n ai-demo -l app=storefront -o jsonpath="{.items[0].metadata.name}"
kubectl logs $storefrontPod -n ai-demo

#Troubleshoot pod on productworker
$productworkerPod = kubectl get pods -n ai-demo -l app=productworker -o jsonpath="{.items[0].metadata.name}"
kubectl logs $productworkerPod -n ai-demo

#Describe pod on AdminSite
$adminsitePod = kubectl get pods -n ai-demo -l app=adminsite -o jsonpath="{.items[0].metadata.name}"
kubectl describe pod $adminsitePod -n ai-demo

#Describe pod on StoreFront
$storefrontPod = kubectl get pods -n ai-demo -l app=storefront -o jsonpath="{.items[0].metadata.name}"
kubectl describe pod $storefrontPod -n ai-demo

#Describe pod on productworker
$productworkerPod = kubectl get pods -n ai-demo -l app=productworker -o jsonpath="{.items[0].metadata.name}"
kubectl describe pod $productworkerPod -n ai-demo
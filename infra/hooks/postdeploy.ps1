# Post-deploy hook to apply Kubernetes manifests
Write-Host "Running post-deploy hook..."

$k8sDir = Join-Path $PSScriptRoot "..\..\k8s"

# Apply ConfigMaps
Write-Host "Applying ConfigMaps..."
kubectl apply -f "$k8sDir\cosmosdb-configmap.yaml" -n ai-demo
kubectl apply -f "$k8sDir\servicebus-configmap.yaml" -n ai-demo

# Apply SecretProviderClass manifests
Write-Host "Applying SecretProviderClass manifests..."
kubectl apply -f "$k8sDir\keyvault-cosmosdb-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-servicebus-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-foundry-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-foundry-api-key-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-foundry-model-deployment-spc.final.yaml" -n ai-demo

# Wait a moment for SecretProviderClass to be ready
Write-Host "Waiting for SecretProviderClass resources to be ready..."
Start-Sleep -Seconds 5

# Apply application deployments
Write-Host "Applying application deployments..."
kubectl apply -f "$k8sDir\storefront-deployment.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\storefront-service.yaml" -n ai-demo
kubectl apply -f "$k8sDir\adminsite-deployment.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\adminsite-service.yaml" -n ai-demo
kubectl apply -f "$k8sDir\productworker-deployment.final.yaml" -n ai-demo

# Wait for both LoadBalancer services to get external IPs
Write-Host "Waiting for services to get external IPs..."
$storefrontIp = ""
$adminsiteIp = ""
for ($attempt = 1; $attempt -le 60; $attempt++) {
    $storefrontIp = kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
    $adminsiteIp = kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"

    if ($storefrontIp -and $adminsiteIp) {
        break
    }

    Start-Sleep -Seconds 5
}

if (!$storefrontIp -or !$adminsiteIp) {
    throw "Timed out waiting for StoreFront and AdminSite external IPs."
}

# Save URLs to azd environment for easy retrieval
azd env set STOREFRONT_URL "http://$storefrontIp"
azd env set ADMINSITE_URL "http://$adminsiteIp"

Write-Host ""
Write-Host "========================================================================================"
Write-Host "Deployment completed successfully!"
Write-Host "========================================================================================"
Write-Host ""

Write-Host "StoreFront URL: http://$storefrontIp" -ForegroundColor Green
Write-Host "AdminSite URL: http://$adminsiteIp" -ForegroundColor Green

Write-Host ""
Write-Host "To retrieve these URLs later, run:" -ForegroundColor Cyan
Write-Host "  azd env get-values" -ForegroundColor Cyan
Write-Host ""
Write-Host "To check the status of your deployments, run:"
Write-Host "  kubectl get pods -n ai-demo"
Write-Host "  kubectl get svc -n ai-demo"
Write-Host ""

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
kubectl apply -f "$k8sDir\keyvault-openai-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-openai-key-spc.final.yaml" -n ai-demo
kubectl apply -f "$k8sDir\keyvault-openai-deployment-spc.final.yaml" -n ai-demo

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

# Wait for services to get external IPs
Write-Host "Waiting for services to get external IPs..."
Start-Sleep -Seconds 10

# Get service endpoints
$storefrontIp = kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>$null
$adminsiteIp = kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>$null

# Save URLs to azd environment for easy retrieval
if ($storefrontIp) {
    azd env set STOREFRONT_URL "http://$storefrontIp"
}
if ($adminsiteIp) {
    azd env set ADMINSITE_URL "http://$adminsiteIp"
}

Write-Host ""
Write-Host "========================================================================================"
Write-Host "Deployment completed successfully!"
Write-Host "========================================================================================"
Write-Host ""

if ($storefrontIp) {
    Write-Host "StoreFront URL: http://$storefrontIp" -ForegroundColor Green
} else {
    Write-Host "StoreFront: External IP pending... Run 'kubectl get svc storefront -n ai-demo' to check status" -ForegroundColor Yellow
}

if ($adminsiteIp) {
    Write-Host "AdminSite URL: http://$adminsiteIp" -ForegroundColor Green
} else {
    Write-Host "AdminSite: External IP pending... Run 'kubectl get svc adminsite -n ai-demo' to check status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "To retrieve these URLs later, run:" -ForegroundColor Cyan
Write-Host "  azd env get-values" -ForegroundColor Cyan
Write-Host ""
Write-Host "To check the status of your deployments, run:"
Write-Host "  kubectl get pods -n ai-demo"
Write-Host "  kubectl get svc -n ai-demo"
Write-Host ""

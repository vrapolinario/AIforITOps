#!/bin/bash
# Post-deploy hook to apply Kubernetes manifests
echo "Running post-deploy hook..."

K8S_DIR="$(dirname "$0")/../../k8s"

# Apply ConfigMaps
echo "Applying ConfigMaps..."
kubectl apply -f "$K8S_DIR/cosmosdb-configmap.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/servicebus-configmap.yaml" -n ai-demo

# Apply SecretProviderClass manifests
echo "Applying SecretProviderClass manifests..."
kubectl apply -f "$K8S_DIR/keyvault-cosmosdb-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-servicebus-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-openai-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-openai-key-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-openai-deployment-spc.final.yaml" -n ai-demo

# Wait a moment for SecretProviderClass to be ready
echo "Waiting for SecretProviderClass resources to be ready..."
sleep 5

# Apply application deployments
echo "Applying application deployments..."
kubectl apply -f "$K8S_DIR/storefront-deployment.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/storefront-service.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/adminsite-deployment.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/adminsite-service.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/productworker-deployment.final.yaml" -n ai-demo

# Wait for services to get external IPs
echo "Waiting for services to get external IPs..."
sleep 10

# Get service endpoints
STOREFRONT_IP=$(kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null)
ADMINSITE_IP=$(kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null)

# Save URLs to azd environment for easy retrieval
if [ -n "$STOREFRONT_IP" ]; then
    azd env set STOREFRONT_URL "http://$STOREFRONT_IP"
fi
if [ -n "$ADMINSITE_IP" ]; then
    azd env set ADMINSITE_URL "http://$ADMINSITE_IP"
fi

echo ""
echo "========================================================================================"
echo "Deployment completed successfully!"
echo "========================================================================================"
echo ""

if [ -n "$STOREFRONT_IP" ]; then
    echo "StoreFront URL: http://$STOREFRONT_IP"
else
    echo "StoreFront: External IP pending... Run 'kubectl get svc storefront -n ai-demo' to check status"
fi

if [ -n "$ADMINSITE_IP" ]; then
    echo "AdminSite URL: http://$ADMINSITE_IP"
else
    echo "AdminSite: External IP pending... Run 'kubectl get svc adminsite -n ai-demo' to check status"
fi

echo ""
echo "To retrieve these URLs later, run:"
echo "  azd env get-values"
echo ""
echo "To check the status of your deployments, run:"
echo "  kubectl get pods -n ai-demo"
echo "  kubectl get svc -n ai-demo"
echo ""

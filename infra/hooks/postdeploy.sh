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
kubectl apply -f "$K8S_DIR/keyvault-foundry-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-foundry-api-key-spc.final.yaml" -n ai-demo
kubectl apply -f "$K8S_DIR/keyvault-foundry-model-deployment-spc.final.yaml" -n ai-demo

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

# Wait for both LoadBalancer services to get external IPs
echo "Waiting for services to get external IPs..."
STOREFRONT_IP=""
ADMINSITE_IP=""

for attempt in $(seq 1 60); do
    STOREFRONT_IP=$(kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
    ADMINSITE_IP=$(kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

    if [ -n "$STOREFRONT_IP" ] && [ -n "$ADMINSITE_IP" ]; then
        break
    fi

    sleep 5
done

if [ -z "$STOREFRONT_IP" ] || [ -z "$ADMINSITE_IP" ]; then
    echo "Timed out waiting for StoreFront and AdminSite external IPs." >&2
    exit 1
fi

# Save URLs to azd environment for easy retrieval
azd env set STOREFRONT_URL "http://$STOREFRONT_IP"
azd env set ADMINSITE_URL "http://$ADMINSITE_IP"

echo ""
echo "========================================================================================"
echo "Deployment completed successfully!"
echo "========================================================================================"
echo ""

echo "StoreFront URL: http://$STOREFRONT_IP"
echo "AdminSite URL: http://$ADMINSITE_IP"

echo ""
echo "To retrieve these URLs later, run:"
echo "  azd env get-values"
echo ""
echo "To check the status of your deployments, run:"
echo "  kubectl get pods -n ai-demo"
echo "  kubectl get svc -n ai-demo"
echo ""

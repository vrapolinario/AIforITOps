# DO NOT RUN THIS SCRIPT DIRECTLY FROM THE SHELL.
# This script is intended to be used for troubleshooting purposes.

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
kubectl delete namespace ai-demo

#Deploy K8s specs
kubectl create namespace ai-demo
kubectl apply -f ./k8s/cosmosdb-configmap.yaml
kubectl apply -f ./k8s/servicebus-configmap.yaml
kubectl apply -f ./k8s/keyvault-cosmosdb-spc.final.yaml
kubectl apply -f ./k8s/keyvault-servicebus-spc.final.yaml
kubectl apply -f ./k8s/keyvault-openai-spc.final.yaml
kubectl apply -f ./k8s/keyvault-openai-key-spc.final.yaml
kubectl apply -f ./k8s/keyvault-openai-deployment-spc.final.yaml
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
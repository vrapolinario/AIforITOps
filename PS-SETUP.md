# Before you get started

All Azure resources necessary to run the sample application as well as exercises can be deployed with the scripts in the `.\scripts` folder. However, before you run them, make sure you update the variables in `.\scripts\env.conf`. This file will be used by the scripts to read variables like Azure Resource Group name, Azure location, etc.

## 1. Provision Azure Resources

All Azure resources necessary to run the application as well as exercises can be deployed with the scripts in the `.\scripts` folder. To get started:

### 1.1 Create Azure Container Registry and Docker images

On an Azure authenticated PowerShell session, run `.\scripts\create-acr-images.ps1`. This script will create a new Resource Group - and so should be the first to run. Next, the script will create the Azure Container Registry (ACR) and login to that registry. Next the script will build the container images for the application. The build process uses ACR Tasks so the images are automatically stored in the registry.

### 1.2 Create Azure Kubernetes Service

Run the `.\scripts\create-aks.ps1` script. The script will start by creating a new User-Assigned Managed Identity and proceed to deploy an Azure Kubernetes Service (AKS) cluster and a node pool. When creating the AKS cluster, the script will assign the User-Assigned Managed Identity to  the cluster. Once the cluster and node pool are provisioned, the script will get the AKS credentials so you can use `kubectl` to interact with the cluster.

We also need to ensure the workload will be deployed to the right nodepool. For that, we'll use custom labels. Run the `.\scripts\set-customlabel.ps1` script.

### 1.3 Create Azure CosmosDB

Run the `.\scripts\create-cosmosdb.ps1` script. This script will create a CosmosDB database and two containers - one for the products and one for the orders.

### 1.4 Create Service Bus

Run the `.\scripts\create-servicebus.ps1` script. This script will create a new Service Bus resource and a queue. This queue will be used by the product worker service to process orders and update the products database/inventory.

### 1.5 Create Azure Key Vault

Run the `.\scripts\create-keyvault.ps1` script. This script creates the Azure Key Vault. It also configures the user account used in this process (the account used to log into the Azure subscription in the PowerShell session) as Key Vault Secrets Officer. Next, the script will grant the User-Assigned Managed Identity associated to the AKS cluster the Key Vault Secrets User role. By doing this, we ensure that the AKS cluster can access the secrets stored in the Key Vault.

### 1.6 Deploy Microsoft Foundry

Run the `.\scripts\deploy-foundry.ps1` script. This script creates a Microsoft Foundry resource, the default Foundry project, and its model deployment. Unless you changed `.\scripts\env.conf`, the script deploys `gpt-4o` using the `GlobalStandard` SKU.

### 1.7 Upload secrets to Azure Key Vault

Next, add the CosmosDB and Service Bus connection strings and Microsoft Foundry model settings as secrets in Azure Key Vault.

Run `.\scripts\upload-secrets-to-keyvault.ps1`. It creates five secrets: the CosmosDB and Service Bus connection strings, the Foundry API key, the Foundry inference endpoint, and the Foundry model deployment name.

## 4 Deploy the application

With the environment in Azure properly configured, it is now time to deploy the app on AKS. The YAML specifications necessary to deploy the app have been stored in the k8s folder.

### 2.1 Update SecretProviderClass specs

 The Key Vault SecretProviderClass YAML specifications need the Key Vault name, user-assigned managed identity client ID, and tenant ID for your environment. Run `.\scripts\update-secretstoreyaml.ps1` to generate `.final.yaml` files for CosmosDB, Service Bus, and the three Foundry secrets.

 Note: For troubleshooting purposes, we are using one SecretProviderClass YAML specification for each secret on Azure Key Vault. That is not necessary in a production environment - however, using multiple SecretProviderClass instances can help isolate issues and is not a security compromise.

### 2.2 Deploy Kubernetes Manifests

Once the files have been configured, it's time to deploy the specs to the AKS cluster. Run the following to accomplish that:

```powershell
kubectl create namespace ai-demo
kubectl apply -f ./k8s/cosmosdb-configmap.yaml
kubectl apply -f ./k8s/servicebus-configmap.yaml
kubectl apply -f ./k8s/keyvault-cosmosdb-spc.final.yaml
kubectl apply -f ./k8s/keyvault-servicebus-spc.final.yaml
kubectl apply -f ./k8s/keyvault-foundry-spc.final.yaml
kubectl apply -f ./k8s/keyvault-foundry-api-key-spc.final.yaml
kubectl apply -f ./k8s/keyvault-foundry-model-deployment-spc.final.yaml
kubectl apply -f ./k8s/storefront-deployment.yaml
kubectl apply -f ./k8s/storefront-service.yaml
kubectl apply -f ./k8s/adminsite-deployment.yaml
kubectl apply -f ./k8s/adminsite-service.yaml
kubectl apply -f ./k8s/productworker-deployment.yaml
```

## 5. Try the application

To test the application, you can access the External IP address of the services. The application has two services: AdminSite and Storefront. To access the IP addresses:

```powershell
kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
```

Copy the IP addresses and paste it into a web browser. You will need one tab for each IP address.

## Workshop

Note: Make sure the environment is up and running before you start this section.

Once the environment has been deployed and you were able to open and use the application, we can start exploring some IT/Ops related tasks. The workshop is divided into four exercises and you can find the workshop guide in the [Workshop folder's ReadMe.md](./Workshop/ReadMe.md) file.

# AI for IT/Ops workshop

This guide explains how to deploy the full cloud-native ecommerce solution to Azure using AKS, CosmosDB, Service Bus, Azure Key Vault, and secure secret management.

## Prerequisites

- Azure subscription
- Azure CLI installed and logged in
- AKS, ACR, CosmosDB, Service Bus, and Key Vault resource quotas available
- Kubernetes CLI (`kubectl`) installed
- Docker Desktop or Docker engine installed
- Clone this repo to a folder on your device using `git clone https://github.com/vrapolinario/AIforITOps.git`

## Before you get started

All Azure resources necessary to run the sample application as well as exercises can be deployed with the scripts in the scripts folder. However, before you run them, make sure you update the variables in `.\scripts\env.conf`. This file will be used by the scripts to read variables like Azure Resource Group name, Azure location, etc.

## 1. Provision Azure Resources

All Azure resources necessary to run the application as well as exercises can be deployed with the scripts in the scripts folder. To get started:

### 1.1 Create Azure Container Registry and Docker images

On a PowerShell session authenticated to your Azure subscription, run `.\scripts\create-acr-images.ps1`.
This script will create a new Resource Group - and so should be the first to run. Next, the script will create the container registry and login to that registry. Next the script will build the container images for the application and push those images to the registry.

### 1.2 Create Azure Kubernetes Service

Run the `.\scripts\create-aks.ps1` script.
The script will deploy an Azure Kubernetes Service (AKS) cluster and a node pool. The script also create a new User-Assigned Managed Identity and assign it to the AKS cluster . Once the cluster and node pool are provisioned, the script will get the AKS credentials so you can use `kubectl` to interact with the cluster. 

We also need to ensure the workload will be deployed to the right nodepool. For that, we'll use custom labels. Run the `.\scripts\set-customlabel.ps1` script.

### 1.3 Create Azure CosmosDB

Run the `.\scripts\create-cosmosdb.ps1` script.
This script will create a CosmosDB database and two containers - one for the products and one for the orders.

### 1.4 Create Service Bus

Run the `.\scripts\create-servicebus.ps1` script.
This script will create a new Service Bus resource and a queue. This queue will be used by the product worker service to process orders and update the products database.

### 1.5 Create Azure Key Vault

Run the `.\scripts\create-keyvault.ps1` script.
This script creates Key Vault. It also configures the user account used in this process (the account used to log into the Azure subscription in the PowerShell session) as Key Vault Secrets Officer. Next, the script will grant the User-Assigned Managed Identity associated to the AKS cluster the Key Vault Secrets User role.

## 2 Upload secrets to Azure Key Vault and grant access to AKS cluster

With the Azure resources created, you can start configuring the environment to support the sample e-commerce application. First, let's start by adding the CosmosDB and Service Hub connection strings as secrets on Azure Key Vault.

For that, run the `.\scripts\upload-secrets-to-keyvault.ps1` script.
This script will create two new secrets on Azure Key Vault, one for the CosmosDB connection string and another one for the Service Bus connection string. These strings contain the access key to these resources, so they should be considered secrets. Please note that additional security can be implemented by configuring your CosmosDB and Service Bus resources' RBAC.

## 3 Deploy the application

With the environment in Azure properly configured, it is now time to deploy the app on AKS. The YAML specifications necessary to deploy the app have been stored in the k8s folder.

### 3.1 Update SecretProviderClass specs

 The Key Vault SecretProviderClass YAML specification needs to be updated with the Key Vault name, User-Assigned Managed Identity ID and Tenant ID values. These are unique for your environment. To create the proper files, run the `.\scripts\update-secretstoreyaml.ps1` script. This script will read the `env.conf` file and query the Azure subscription you are using. Then the script will create a new version of `.\k8s\keyvault-cosmosdb-spc.yaml` and `.\k8s\keyvault-servicebus-spc.yaml` with 'final' added to the file name.

### 3.2 Deploy Kubernetes Manifests

Once the files have been configured, it's time to deploy the specs to the AKS cluster. Run the following to accomplish that:

```powershell
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
```

## 4. Try the application

To test the application, you can access the External IP address of the services. The application has two services: AdminSite and Storefront. To access the IP addresses:

```powershell
kubectl get svc storefront -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
kubectl get svc adminsite -n ai-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
```

Copy the IP addresses and paste it into a web browser. You will need one tab for each IP address.

## To-Do

1. Add AI components
2. Add instructions for workshop for AI for Ops
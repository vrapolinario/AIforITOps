# Exercise 1 - Identity

In this exercise we will deploy the sample E-commerce application. This application is deployed in an Azure Kubernetes Service cluster. However, the application uses other Azure services such as CosmosDB, Service Bus, and Azure OpenAI. To access these services, the AKS cluster needs access to sensitive information such as connection strings, passwords, and access keys. Instead of hardcoding these values into the application source code, it's a best practice to store them in a secure location - such as Azure Key Vault - and ensure that only the nodes in your AKS cluster can access it.

In this exercise you will:

- Ensure only the AKS cluster has access to the secrets via Managed Identity.
- Test the application connection to Azure OpenAI.

## Review secrets on Azure Key Vault

As part of the deployment, we need to ensure that sensitive information such as connection strings, passwords, and access keys are securely stored and only accessible by the authorized Azure services:

- Open the Azure portal at <https://portal.azure.com>.
- Navigate to the resource group and open the Azure Key Vault.
- Expand Objects in the left-hand side menu and click Secrets.
- Make sure you have the following secrets:
  - CosmosDBConnectionString
  - OpenAIAPIKey
  - OpenAIDeploymentName
  - OpenAIEndpoint
  - ServiceBusConnectionString
- To validate the secret content, open one of the secrets, and click the current version. On the Secret version page, click Show Secret Value. Notice that it contains the value expected for the secret you selected.

These secrets are used by the application to communicate with the Azure services. Instead of hardcoding this information into the application code, our developer counterparts used placeholders (variables) that expect these values to be replaced at deployment time.

## Ensure only the AKS cluster can access the Key Vault secrets

To ensure the secrets on the Azure Key Vault are not leaked to an unauthorized entity, we will ensure only the Azure Kubernetes Service has access to these secrets.

- On the Azure portal, navigate to the resource group for this workshop.
- Click the Managed Identity.
- On the Managed Identity page, click Associated resources (Preview) in the left-hand side menu.
- Make sure the AKS cluster and the Virtual Machine Scale set are listed. This means that all nodes in the AKS cluster have this Managed Identity associated to them.
- Close the Managed Identity page.
- Back to the resource group view, click the Azure Key Vault.
- On the Key Vault page, click Access Control (IAM) on the left-hand side menu.
- On the Access Control (IAM) page, click + Add and then select Add role assignment.
- On the Add role assignment page, type "Key Vault Secrets User", select the Key Vault Secrets User from the list and click Next.
- On the Members tab, for the "Assign access to" section select Managed Identity and click "+ Select members" in the Members section.
- On the Select managed identities menu on the right-hand side, click the Managed identity drop-down menu and select User-assigned managed identity.
- From the list, select the managed identity created for this workshop and click Select.
- Click Review + assign, twice.

With the Key Vault Secrets User role assigned to the Managed identity, the AKS cluster nodes have "Read secret contents" access - meaning these nodes can retrieve the secrets.

## Explore Kubernetes specifications for application deployment

All Kubernetes resources can be found in the K8s folder from the application:

- Open Windows Explorer on your machine.
- Navigate to the '\AIforITOps\k8s' folder.
- Note that all Kubernetes resources to be deployed have a YAML specification file.
- Double-click the 'adminsite-deployment.final.yaml' file. (Make sure it opens with Visual Studio Code or your IDE of choice)
- Scroll down to the volumeMounts section and notice that the deployment of the application expects to get the same secrets from Azure Key Vault. Close the file.

- Double-click the 'keyvault-openai-key-spc.final.yaml' file.
- This file represents the secret to be mounted into the deployment we just explored.
- Note that the file has been completed with the values for userAssignedIdentityID, keyvaultName, and tenantID. This was done as part of the deployment process for the application.
- Close the file.

## Check Kubernetes resources

- On the Azure portal, navigate to the workshop resource group and open the AKS cluster.
- On the Kubernetes service page, expand Kubernetes resources on the left-hand side menu and click namespaces.
- Note that the ai-demo namespace has been deployed.
- Click Workloads on the left-hand side menu.
- Make sure the three deployments that compose our application are present and the Ready column shows a green status: storefront, adminsite, and productworker.
- Click Services and ingresses on the left-hand side menu.
- On the list of services, click the External IP address of the storefront and adminsite. Both should open on a new tab.

## Use the E-commerce sample application

- Open the Admin Site web page from the previous section.
- Click the Admin tab.
- Click Add New Product.
- On the Add Product page, type "Modern Gray Sofa" on the Name text box.
- Click the AI generated description button. Notice that the Description is filled out for you by the Azure OpenAI service.
- Enter 1099 for the price of the product then click the Choose File button next to Product Image.
- On the pop-up to select the file, navigate `\GitHub\AIforITOps\StoreSampleMedia` and select the ModernSofaGray file. Enter 10 for quantity and click Add.
- Open the Home page for the StoreFront. You might need to refresh the page to see the newly added product.

## Use StoreFront chatbot

- On the StoreFront page, click the Chat option on the lower, right-hand corner.
- On the Ask me anything box, type "What team has been named champions of the 2025 Formula 1 season" and click the Send button.
- Notice that the application has been configured to limit the Azure OpenAI responses to furniture related questions only.
- On Windows Explorer, navigate to `.\StoreFront\Controllers\ChatbotController.cs` and open that file with Visual Studio Code.
- This file represents the configuration of the Chatbot for the StoreFront.
- On Visual Studio Code, navigate to line 42 and note the system role attributed to the ChatBot.

This information is sent to the Azure OpenAI service when the webpage has a request for chat. Later in the workshop, we will explore how to configure Prompt Shielding, which is configured as part of the Azure OpenAI service model deployment.

- Close Visual Studio Code.

## What's next?

Exercise 2 - [Networking](./2-Networking.md).
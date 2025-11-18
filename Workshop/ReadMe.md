# Welcome to the AI for IT/Ops workshop

This workshop was designed to provide ITPros an understanding of how AI-enabled applications can be managed in Azure. In this lab we will cover how to deploy an AI-enabled application as well as management aspects related to Identity, networking, monitoring, and more!

## Objectives

This workshop has the following objectives:

- Provide an overview for ITPros on how to manage AI-enabled applications on Azure.
- Explain the nuances of managing, monitoring, and securing Azure services for AI-enabled applications.
- Provide a blueprint on how to approach deploying AI-enabled applications on Azure.

### Exercise 1 - Identity

In this exercise we will deploy the sample E-commerce application. This application is deployed in an Azure Kubernetes Service cluster. However, the application uses other Azure services such as CosmosDB, Service Bus, and Azure OpenAI. To access these services, the AKS cluster needs access to sensitive information such as connection strings, passwords, and access keys. Instead of hardcoding these values into the application source code, it's a best practice to store them in a secure location - such as Azure Key Vault - and ensure that only the nodes in your AKS cluster can access it.

In this exercise you will:

- Ensure only the AKS cluster has access to the secrets via Managed Identity.
- Test the application connection to Azure OpenAI.

### Review secrets on Azure Key Vault

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

### Ensure only the AKS cluster can access the Key Vault secrets

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

### Explore Kubernetes specifications for application deployment

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

### Check Kubernetes resources

- On the Azure portal, navigate to the workshop resource group and open the AKS cluster.
- On the Kubernetes service page, expand Kubernetes resources on the left-hand side menu and click namespaces.
- Note that the ai-demo namespace has been deployed.
- Click Workloads on the left-hand side menu.
- Make sure the three deployments that compose our application are present and the Ready column shows a green status: storefront, adminsite, and productworker.
- Click Services and ingresses on the left-hand side menu.
- On the list of services, click the External IP address of the storefront and adminsite. Both should open on a new tab.

### Use the E-commerce sample application

- Open the Admin Site web page from the previous section.
- Click the Admin tab.
- Click Add New Product.
- On the Add Product page, type "Modern Gray Sofa" on the Name text box.
- Click the AI generated description button. Notice that the Description is filled out for you by the Azure OpenAI service.
- Enter 1099 for the price of the product then click the Choose File button next to Product Image.
- On the pop-up to select the file, navigate `\GitHub\AIforITOps\StoreSampleMedia` and select the ModernSofaGray file. Enter 10 for quantity and click Add.
- Open the Home page for the StoreFront. You might need to refresh the page to see the newly added product.

### Use StoreFront chatbot

- On the StoreFront page, click the Chat option on the lower, right-hand corner.
- On the Ask me anything box, type "What team has been named champions of the 2025 Formula 1 season" and click the Send button.
- Notice that the application has been configured to limit the Azure OpenAI responses to furniture related questions only.
- On Windows Explorer, navigate to `.\StoreFront\Controllers\ChatbotController.cs` and open that file with Visual Studio Code.
- This file represents the configuration of the Chatbot for the StoreFront.
- On Visual Studio Code, navigate to line 42 and note the system role attributed to the ChatBot.

This information is sent to the Azure OpenAI service when the webpage has a request for chat. Later in the workshop, we will explore how to configure Prompt Shielding, which is configured as part of the Azure OpenAI service model deployment.

- Close Visual Studio Code.

## Exercise 2 - Networking

By implementing a secure method to store secrets you are taking the first step towards a more secure posture for your AI-enabled application. However, the default implementation of services like Azure OpenAI are still very broad, allowing any service that has the Endpoint and API Keys to communicate with it. In this exercise we will cover how to improve the security of AI services on Azure from a networking standpoint.

In this exercise you will:

- Configure Firewalls and Virtual Networks for Azure OpenAI
- Confirm Azure OpenAI rejects calls from unauthorized networks.
- Configure Azure OpenAI virtual network integration with Azure Kubernetes Service.

### Implement Firewall and virtual networks for Azure OpenAI

By default, Azure OpenAI (and other Azure AI services) have a default configuration of allowing access from all Networks. To change that:

- Open the Azure Portal and navigate to the resource group for this workshop.
- Click the Azure OpenAI service.
- On the Azure OpenAI service page expand Resource Management on the left-hand side menu and click Networking.
- Click Generate Custom Domain Name and type a unique name for the value for Custom Domain Name.
- Click Save.
- Once the Azure portal shows the notification that the action was completed, refresh the browser tab.
- Back to the Networking page of the Azure OpenAI service, change the Allow access from to Selected Networks and Private Endpoints.
- Click Save.
- Open the AdminPage of the application if not open already.
- Click the Admin tab and click Add New Product.
- On the Add Product page, type "Classic Bed" for the Name and click the AI generated description.
- Note that the description will not be filled by the Azure OpenAI service.
- Open a new browser tab, type <https://portal.azure.com>, and navigate to the workshop resource group.
- Open the AKS cluster.
- Expand Kubernetes resources on the left-hand side menu and click Workloads.
- Click the adminsite deployment.
- Click Live logs on the left-hand side menu.
- On the Live Logs page, click the Select a Pod drop-down menu and click the existing pod.
- Return to the AdminSite of the E-commerce application and try to generate the description again.
- Once you click the button, return to the Azure portal and notice that the logs from the attempt are now shown.
- Click the Pause button to prevent the page from returning to the bottom of the logs.
- Scroll up on the logs until you find a log with the Log content with an error code 403 - Access denied due to Virtual Network/Firewall rules.
- Open the other Azure portal tab on which the Azure OpenAI service is open.
- On the Networking page of the Azure OpenAI service, click + Add existing virtual network.
- On the right-hand side panel click the Virtual networks drop-down box and select the AKS vnet.
- On the Subnets drop-down menu click the AKS subnet.
- Click Enable and wait for the process to Enable the Service endpoint. Once completed click Add and then Save on the Networking page.
- Once this process completes, return to the AdminSite and try to generate a new description for the Classic Bed.
- This time, the application should be able to communicate with the Azure OpenAI service and the description should be generated.

### Implement Private Endpoints for Azure OpenAI

Private Endpoints provide an even higher security posture for workloads on Azure as it requires the source of the communication to reach the target resource via a controlled, private endpoint.

- Return to the Networking page of the Azure OpenAI service in the Azure portal.
- On the Firewall and virtual networks tab, select Disabled. NOTE: This will disable access to this resource, with Private Endpoint being the exclusive way to access it.
- Click Save.
- Open the Azure Kubernetes Service tab from the previous section.
- Click the Play button for the page to show new logs from the AdminSite pod.
- Open the AdminSite page and try to generate a new description for the Classic Bed.
- Return to the Azure Kubernetes Service page and Pause the logs.
- Scroll up until you see the error message with code 403: Public access is disabled. Please configure private endpoint.
- Return to the Azure OpenAI tab on Edge.
- Click the Private endpoint connections tab and click + Private endpoint.
- On the Create a private endpoint page, make sure the Resource group is the resource group for the workshop.
- Enter the following values for the Instance details and click Next.

- Name: Enter a unique name.
- Network (leave default)
- Region: Make sure the location is set to the same as the resources for the workshop.

- On the Resource tab, make sure the Resource type is Microsoft.CognitiveServices/accounts, the Resource is the one you created in the previous step and that the Target sub-resource is account. Click Next.
- On the Virtual Network tab, make sure the aks-vnet is selected for Virtual network and the subnet is the aks-subnet. Click Next.
- Click Next on the DNS and Tags tabs.
- On the Review + Create tab, click Create.
- Wait for the resource creation to finalize. Once it's completed, close the deployment page.
- Navigate back to the Azure OpenAI service in the Azure portal.
- Click the Keys and Endpoint on the left-hand side menu.
- Copy the content of the Endpoint and close the Azure OpenAI page. Note: This is a URL format, do not copy the Keys.
- Navigate to the workshop resource group and open the Azure Key Vault.
- On the Key Vault page, expand Objects and click Secrets.
- Select the OpenAIEndpoint secret and click + New Version.
- On the Secret value, enter the previously copied endpoint for the OpenAI service. Note: Click the show password icon (eye icon) and make sure the value corresponds to the previously copied information.
- Click Create and close the Key Vault page.
- Switch to the Azure Kubernetes Service tab on your browser, from the previous section. You should be in the Live Logs page.
- On the left-hand side menu, click Overview.
- Under Workloads, select the existing pod and click Delete.
- On the right-hand side panel, mark the Confirm delete checkbox and click Delete.
- A new pod will be started immediately. Click Refresh and make sure the new pod has the Running Status.
- Switch to the AdminSite and test if the AI generated description button works. This time, the application should be able to communicate with the Azure OpenAI service and the description should be generated.

## Exercise 3 - Monitoring

Once deployed, monitoring any Azure service is an essential task of any Cloud IT Admin. By default, Azure provides essential monitoring mechanisms for Azure services, but these can be further configured to support your specific needs.

In this exercise you will:

- Use the built-in Metrics on Azure OpenAI to monitor the service performance and health.
- Configure Azure Log Analytics integration for Azure OpenAI.
- Use Log Analytics to query the log data for Azure OpenAI.

### Monitor Azure OpenAI metrics

- On your Azure portal window, navigate to the workshop resource group, if not there already.
- Open the Azure OpenAI service.
- On the Overview page, select the Monitor tab at the center-bottom of the page.
- Take a moment to analyze the existing dashboard built for you by default.
- Next, expand Monitoring on the left-hand side menu and click Metrics.
- On the Metrics page, click the Metric drop-down menu and select Azure OpenAI Requests.
- A chart indicating how many requests happened in the last 24hrs should be displayed. Note: It takes some time for the metrics data to be shown in the Metrics dashboard, so you might not see all requests right away.
- Click + Add metric.
- On the new Metric added to the chart view, select Generated Completion Tokens.
- Take a moment to review the additional metrics available for this service. In the Metrics page, you can combine any metric that you'd like to analyze.
- Still on the Azure OpenAI page, click Overview in the left-hand side menu and click Go to Azure AI Foundry portal.
- On the Azure AI Foundry page, click Monitoring on the left-hand side menu, select your deployment from the dropdown and click Let's go.
- The data shown in this view is the same as in the Metrics view from the Azure portal. However, Azure AI Foundry shows the most frequently used metrics in this default dashboard.
- Take a moment to explore the dashboard in Azure AI Foundry. Once you are done, you can close the Azure AI Foundry tab.

### Integrate with Log Analytics

- On the Azure portal, navigate to the workshop resource group if not there already.
- Click the Azure OpenAI service.
- Expand Monitoring on the left-hand side menu and click Diagnostic settings.
- Click Edit setting for the OpenAI-Diagnostics.
- On the Diagnostic setting page, select the AllMetrics checkbox.
- Review the remaining sections of the Diagnostic setting and when done, click save.
- Click Logs under Monitoring on the left-hand side menu.
- Close the Welcome to Log Analytics message and Queries hub.

Note: It takes several minutes for data to flow from the Azure OpenAI service to Log Analytics. If you skipped the previous exercises, you might want to open the E-commerce app, trigger the communication with the Azure OpenAI service and return to this exercise later.

- On the right-hand side, change Simple mode to KQL mode in the drop-down menu.
- Copy the content below and paste it into the New Query 1 tab.

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where ResultSignature == "200"
| order by TimeGenerated desc
```

- Click the Run button.
- The above query will return the log entries of all successful requests to the Azure OpenAI. Take a moment to analyze the data in these entries. Once you are done, you can close the Azure OpenAI page and return to the workshop resource group.

## Exercise 4 - Governance and DLP

In addition to managing and monitoring your AI-enabled applications and Azure services, you might also want to consider establishing governance processes to ensure new and existing resources adhere to your business needs as well compliance and security requirements.

In this exercise you will:

- Use Azure Policy to identify AI services out of compliance.
- Configure Azure OpenAI for Data Loss Prevention (DLP).
- Check Policy status to confirm resources are compliant.

### Configure Azure policy for Azure OpenAI

With Azure Policy, you can check and/or enforce resource compliance at subscription or resource group level. Azure provides built-in policies for Azure AI services that can be leveraged.

- On the Azure portal, navigate to the Azure OpenAI service.
- On the Azure OpenAI service page, click the JSON View on the right-hand side under Essentials.
- On the right-hand side panel for Resource JSON, take a note of the type: Microsoft.CognitiveServices/accounts.
- Close the Azure OpenAI page.
- On the Azure portal, type "Policy" on the Search bar at the top-center and select Policy.
- On the Azure Policy page, select Compliance on the right-hand side menu and click Assign policy.
- On the Assign policy page, click the ... next to Scope.
- On the Scope panel on the right-hand side, select the workshop resource group from the drop-down menu and click Select.
- Click the ... on the Policy definition under Basics.
- On the Available Definitions panel on the right-hand side, click the Search box and type "Cognitive".
- Select the Configure Cognitive Services accounts with private endpoints policy and click Add.
- Toggle the Policy enforcement switch to disabled. Note: This will effectively set this policy as Assessment only. Click Next.
- On the Parameters page, click the ... next to the Private endpoint subnet ID.
- On the right-hand side panel, select the aks-vnet for VirtualNetworks and aks-subnet for the subnets. Click Select.
- Click Review + Create then click Create.

It might take 5-15 minutes for the policy assessment to complete. You can continue to the next steps as we'll return to this view later.

- Still on the Policy page, expand authoring on the left-hand side menu and click Definitions.
- On the search box, type "Cognitive" and select the Configure Cognitive Services accounts with private endpoints policy which we selected before.
- Under the definition JSON, navigate to lines 36 and 37. These lines in this particular JSON ensure that only Azure resources of the type Microsoft.CognitiveServices/accounts will be affected by this policy definition.
- Close the definition page.

### Set up Data loss prevention for Azure OpenAI

Data loss prevention should encompass a series of analysis and tactics to prevent data from being leaked, stolen or deleted from your environment. From a AI service standpoint, Azure AI services can add an additional layer of protection by preventing your data from leaving the environment.

- Open the PowerShell session. Note: If you closed the PowerShell session, you might need to run az login again.
- On the PowerShell session, type:

```powershell
az cognitiveservices account show -g "{resource-group-name}"  -n "{openai-service-name}" --query "{publicNetworkAccess: properties.publicNetworkAccess, restrictOutboundNetworkAccess: properties.restrictOutboundNetworkAccess}"
```

- The above command checks for the Public Network Access policy configured for the Azure OpenAI service. By default, this is set as Disabled, which means data can flow from the Azure OpenAI service to any address on the internet.
- On the PowerShell session, type:

```powershell
az rest --method patch --uri "/subscriptions/{your-subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.CognitiveServices/accounts/{openai-service-name}?api-version=2024-10-01" --headers "Content-Type=application/json" --body '{\"properties\": { \"publicNetworkAccess\": \"Enabled\", \"restrictOutboundNetworkAccess\": true, \"allowedFqdnList\": [ \"microsoft.com\" ] }}'
```

- To check the results, type:

```powershell
az cognitiveservices account show -g "{resource-group-name}"  -n "{openai-service-name}" --query "{publicNetworkAccess: properties.publicNetworkAccess, restrictOutboundNetworkAccess: properties.restrictOutboundNetworkAccess}"
```

## Bonus content (Optional) - Prompt Shielding for Azure OpenAI

An important aspect of managing AI services is to ensure the interaction between the users and the chat service is protected against harmful content and security risks. As we've seen in a previous exercise, you can configure the application you use to limit the topics your AI service is able to work with. In addition, Azure AI Foundry provides mechanisms to help protect your model deployment from harmful content and jailbreak exploits.

In this exercise you will:

- Configure Guardrails and controls for Azure OpenAI

### Guardrails and controls on Azure AI Foundry

- On the Azure portal, navigate to the workshop resource group if not there already.
- Click the Azure OpenAI service.
- On the Azure OpenAI service page, click the Go to Azure AI Foundry portal.
- On the Azure AI Foundry page, click Guardrails + Controls on the left-hand side menu.
- Click the Content filters tab and click the + Create content filter.
- On the Add basic information, leave the default name and click Next.
- On the Setup input filter take a moment to review the different categories.
- Change the Prompt shields for indirect attacks to Annotate and block.
- Click Next.
- Click Next for the Set output filter.
- On the Apply filter to deployments, select the existing deployment and click Next.
- On the Review page, click Create filter.

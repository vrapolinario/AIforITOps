# Exercise 2 - Networking

By implementing a secure method to store secrets you are taking the first step towards a more secure posture for your AI-enabled application. However, the default implementation of services like Microsoft Foundry are still very broad, allowing any service that has the Endpoint and API Keys to communicate with it. In this exercise we will cover how to improve the security of AI services on Azure from a networking standpoint.

In this exercise you will:

- Configure Firewalls and Virtual Networks for Microsoft Foundry
- Confirm Microsoft Foundry rejects calls from unauthorized networks.
- Configure Microsoft Foundry virtual network integration with Azure Kubernetes Service.

## Implement Firewall and virtual networks for Microsoft Foundry

By default, Microsoft Foundry (and other Azure AI services) have a default configuration of allowing access from all Networks. To change that:

- Open the Azure Portal and navigate to the resource group for this workshop.
- Click the Microsoft Foundry service. (Note: Look for the Foundry resource of type "Foundry" and not "Foundry Project".)
- On the Microsoft Foundry service page expand Resource Management on the left-hand side menu and click Networking.
- On the Networking page of the Microsoft Foundry service, change the Allow access from to Selected Networks and Private Endpoints.
- Click Save.
- Open the AdminPage of the application if not open already.
- Click the Admin tab and click Add New Product.
- On the Add Product page, type "Classic Bed" for the Name and click the AI generated description.
- Note that the description will not be filled by the Microsoft Foundry service.
- Open a new browser tab, type <https://portal.azure.com>, and navigate to the workshop resource group.
- Open the AKS cluster.
- Expand Kubernetes resources on the left-hand side menu and click Workloads.
- Click the adminsite deployment.
- Click Live logs on the left-hand side menu.
- On the Live Logs page, click the Select a Pod drop-down menu and click the existing pod.
- Return to the AdminSite of the E-commerce application and try to generate the description again.
- Once you click the button, return to the Azure portal page with the AKS pod and notice that the logs from the attempt are now shown.
- Click the Pause button to prevent the page from returning to the bottom of the logs.
- If needed, scroll up on the logs until you find a log with the Log content with an error code 403. This log confirms that access was denied due to Virtual Network/Firewall rules.
- Open the other Azure portal tab on which the Microsoft Foundry service is open.
- On the Networking page of the Microsoft Foundry service, click + Add existing virtual network.
- On the right-hand side panel click the Virtual networks drop-down box and select the AKS vnet.
- On the Subnets drop-down menu click the AKS subnet.
- Click Enable and wait for the process to Enable the Service endpoint. Once completed click Add and then Save on the Networking page.
- Once this process completes, return to the AdminSite and try to generate a new description for the Classic Bed.
- This time, the application should be able to communicate with the Microsoft Foundry service and the description should be generated.

## Implement Private Endpoints for Microsoft Foundry

Private Endpoints provide an even higher security posture for workloads on Azure as it requires the source of the communication to reach the target resource via a controlled, private endpoint.

- Return to the Networking page of the Microsoft Foundry service in the Azure portal.
- On the Firewall and virtual networks tab, select Disabled. NOTE: This will disable access to this resource, with Private Endpoint being the exclusive way to access it.
- Click Save.
- Open the Azure Kubernetes Service tab from the previous section.
- Click the Play button for the page to show new logs from the AdminSite pod.
- Open the AdminSite page and try to generate a new description for the Classic Bed.
- Return to the Azure Kubernetes Service page and Pause the logs.
- Scroll up until you see the error message with another code 403. This confirms public access is disabled.
- Return to the Microsoft Foundry tab on Edge.
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
- Switch to the AdminSite and test if the AI generated description button works. This time, the application should be able to communicate with the Microsoft Foundry service and the description should be generated.

## What's next?

Exercise 3 - [Monitoring](./3-Monitoring.md).

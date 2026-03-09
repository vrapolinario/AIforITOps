# Exercise 2 - Networking

By implementing a secure method to store secrets you are taking the first step towards a more secure posture for your AI-enabled application. However, the default implementation of services like Azure OpenAI are still very broad, allowing any service that has the Endpoint and API Keys to communicate with it. In this exercise we will cover how to improve the security of AI services on Azure from a networking standpoint.

In this exercise you will:

- Configure Firewalls and Virtual Networks for Azure OpenAI
- Confirm Azure OpenAI rejects calls from unauthorized networks.
- Configure Azure OpenAI virtual network integration with Azure Kubernetes Service.

## Implement Firewall and virtual networks for Azure OpenAI

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

## Implement Private Endpoints for Azure OpenAI

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

## What's next?

Exercise 3 - [Monitoring](./3-Monitoring.md).
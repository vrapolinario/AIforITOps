# Exercise 4 - Governance and DLP

In addition to managing and monitoring your AI-enabled applications and Azure services, you might also want to consider establishing governance processes to ensure new and existing resources adhere to your business needs as well compliance and security requirements.

In this exercise you will:

- Use Azure Policy to identify AI services out of compliance.
- Configure Azure OpenAI for Data Loss Prevention (DLP).
- Check Policy status to confirm resources are compliant.

## Configure Azure policy for Azure OpenAI

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

## Set up Data loss prevention for Azure OpenAI

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

## What's next?

Bonus - [Bonus content](./Bonus.md).
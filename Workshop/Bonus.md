# Bonus content (Optional) - Prompt Shielding for Azure OpenAI

An important aspect of managing AI services is to ensure the interaction between the users and the chat service is protected against harmful content and security risks. As we've seen in a previous exercise, you can configure the application you use to limit the topics your AI service is able to work with. In addition, Azure AI Foundry provides mechanisms to help protect your model deployment from harmful content and jailbreak exploits.

In this exercise you will:

- Configure Guardrails and controls for Azure OpenAI

## Guardrails and controls on Azure AI Foundry

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

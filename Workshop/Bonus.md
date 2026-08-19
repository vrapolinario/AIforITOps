# Bonus content (Optional) - Prompt Shielding for Azure OpenAI

An important aspect of managing AI services is to ensure the interaction between the users and the chat service is protected against harmful content and security risks. As we've seen in a previous exercise, you can configure the application you use to limit the topics your AI service is able to work with. In addition, Microsoft Foundry provides mechanisms to help protect your model deployment from harmful content and jailbreak exploits.

In this exercise you will:

- Configure Guardrails and controls for Microsoft Foundry

Note: This exercise requires you to remove the network restrictions you configured in the previous exercise. If you want to keep the network restrictions, you can skip this exercise.

## Guardrails and controls on Azure AI Foundry

- On the Azure portal, navigate to the workshop resource group if not there already.
- Click the Microsoft Foundry service. (Note: Look for the Foundry resource of type "Foundry" and not "Foundry Project".)
- On the Microsoft Foundry service page, click the Go to Foundry portal.
- On the Microsoft Foundry page, make sure the New Foundry toggle is checked.
- Click Build on the top right-hand corner and select Deployments on the left menu.
- Click the gpt-4o deployment, and select Guardrails on the left menu.
- Click the Create button on the right.
- On the Create guardrail page, review the options to configure the guardrail. For this exercise, review the options available.
- Select the checkbox for Indirect prompt injections.
- Click Next.
- Select the gpt-4o deployment at the bottom and click Next.
- On the Review page, click Create.

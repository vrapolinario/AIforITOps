# Exercise 3 - Monitoring

Once deployed, monitoring any Azure service is an essential task of any Cloud IT Admin. By default, Azure provides essential monitoring mechanisms for Azure services, but these can be further configured to support your specific needs.

In this exercise you will:

- Use the built-in Metrics on Azure OpenAI to monitor the service performance and health.
- Configure Azure Log Analytics integration for Azure OpenAI.
- Use Log Analytics to query the log data for Azure OpenAI.

## Monitor Azure OpenAI metrics

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

## Integrate with Log Analytics

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
- 
## What's next?

Exercise 4 - [Governance](./4-Governance.md).
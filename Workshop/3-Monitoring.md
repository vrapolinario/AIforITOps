# Exercise 3 - Monitoring

Once deployed, monitoring any Azure service is an essential task of any Cloud IT Admin. By default, Azure provides essential monitoring mechanisms for Azure services, but these can be further configured to support your specific needs.

In this exercise you will:

- Use the built-in Metrics on Microsoft Foundry to monitor the service performance and health.
- Configure Azure Log Analytics integration for Microsoft Foundry.
- Use Log Analytics to query the log data for Microsoft Foundry.

## Monitor Microsoft Foundry metrics

- On your Azure portal window, navigate to the workshop resource group, if not there already.
- Open the Microsoft Foundry service. (Note: Look for the Foundry resource of type "Foundry" and not "Foundry Project".)
- Expand Monitoring on the left-hand side menu and click Metrics.
- On the Metrics page, click the Metric drop-down menu and select Azure OpenAI Requests.
- A chart indicating how many requests happened in the last 24hrs should be displayed. (Note: It takes some time for the metrics data to be shown in the Metrics dashboard, so you might not see all requests right away.)
- Click + Add metric.
- On the new Metric added to the chart view, select Generated Completion Tokens.
- Take a moment to review the additional metrics available for this service. In the Metrics page, you can combine any metric that you'd like to analyze.
- Still on the Microsoft Foundry page, click Overview in the left-hand side menu and click Go to Foundry portal.
- On the Microsoft Foundry page, make sure the New Foundry toggle is checked.
- Click Build on the top, right-hand side tab.
- On the Build page, click Deployments on the left-hand side menu.
- Click the gpt-4o deployment, and select the Monitor tab.
- The data shown in this view is the same as in the Metrics view from the Azure portal. However, Microsoft Foundry shows the most frequently used metrics in this default dashboard.
- Take a moment to explore the dashboard in Microsoft Foundry. Once you are done, you can close the Microsoft Foundry tab and return to the Azure portal.

## Integrate with Log Analytics

- On the Azure portal, navigate to the workshop resource group if not there already.
- Click the Microsoft Foundry service.
- Expand Monitoring on the left-hand side menu and click Diagnostic settings.
- Click Edit setting for the foundry-diagnostics.
- Review the the sections of the Diagnostic setting. These settings are already configured to send the logs to the Log Analytics workspace created during the deployment of this workshop. Close the Diagnostic setting page and return to the Microsoft Foundry page.
- Click Logs under Monitoring on the left-hand side menu.
- Close the Meet the Observability agent message and Queries hub.

Note: It takes several minutes for data to flow from the Microsoft Foundry service to Log Analytics. If you skipped the previous exercises, you might want to open the E-commerce app, trigger the communication with the Microsoft Foundry service and return to this exercise later.

- On the right-hand side, change Simple mode to KQL mode in the drop-down menu.
- Copy the content below and paste it into the New Query 1 tab.

```kusto
AzureDiagnostics
| where ResourceProvider == "MICROSOFT.COGNITIVESERVICES"
| where ResultSignature == "200"
| order by TimeGenerated desc
```

- Click the Run button.
- The above query will return the log entries of all successful requests to the Microsoft Foundry. Take a moment to analyze the data in these entries. Once you are done, you can close the Microsoft Foundry page and return to the workshop resource group.

Note: You can change the ResultSignature value to 403 to see the failed requests. You can also change the order by clause to order by TimeGenerated asc to see the oldest entries first.

## What's next?

Exercise 4 - [Governance](./4-Governance.md).

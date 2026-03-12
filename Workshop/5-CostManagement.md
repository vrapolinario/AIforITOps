# Exercise 5 - Azure AI services Cost Management

> Note: It takes 24 hours for cost data from Azure services to show in the Cost Management + Billing dash If you just deployed this workshop environment, you might want to wait until you start this exercise.

You’ve deployed the AI-enabled application and its components. Leadership now asks: *“How much are these AI workloads costing us, and how do we keep them under control as usage grows?”*

In this exercise you will:

- Identify AI-related costs using Cost Management.
- Analyze cost drivers such as token usage.
- Configure budgets and alerts for AI workloads.

## Identify AI workload costs in Cost Management

In this section, you’ll locate and isolate the costs associated with your AI-enabled app.

### Open cost analysis for the workshop scope

- Open the Azure portal at <https://portal.azure.com>.
- In the search bar on the top, type Cost Management and select Cost Management from the results.
- On the left-hand side panel, expand Report + analytics and select Cost analysis.
- At the top, click Change next to scope (By default, the scope is set to the subscription).
- On the right-hand side panel, click the Root Management Group, then the Subscription, and finally select the Resource group used for the workshop. Click Select.
- Click the All views tabs, and select the Daily Costs under Recommended.
- On the filters available, select the time period for the analysis (e.g., Last 7 days, Last 30 days, or a custom range covering the duration of the workshop).
- Still on the filters, click Add filter.
- From the drop-down menu, select Resource type, them select Microsoft.CognitiveServices/accounts for the resource type, and click the green check to apply.

Take a moment to familiarize yourself with the Cost analysis interface. You can change the visualization type (e.g., chart, table) and how costs are grouped (e.g., by service, by resource).

## Tag resources for better cost attribution

To make AI workload costs easier to track, you’ll apply tags to key resources.

### Decide on a tagging scheme

Use a simple scheme such as:

- **Tag name:** `CostCenter`  
- **Value:** `AIforITOps`  

> Note: In a production environment, you might have a more complex tagging strategy, but for this workshop, a single tag will help you easily identify relevant costs.

### Tag key AI resources

- In the Azure portal, navigate to the Azure OpenAI resource.
- In the left-hand menu, select Tags.  
- Add a new tag:
  - Name: `CostCenter`  
  - Value: `AIforITOps`  
- Select Apply.

### Use tags in cost analysis

- Go back to Cost Management → Cost analysis.
- Open the Daily costs view under Recent.
- Make sure the cost for all resources are being shown (as we haven't filtered by tags type yet).
- Click Add Filter:
  - Select Tag → `CostCenter` = `AIforITOps`.

> Note: It may take some time for the tag to be listed in the filter options after you create it.

## Analyze Azure OpenAI usage and cost drivers

Now you’ll focus specifically on Azure OpenAI and understand how usage patterns affect cost.

### Isolate Azure OpenAI costs

- In Cost analysis, keep the scope to your workshop resource group or subscription.
- Add a Filter:
   - Service name = `Foundry Models`.
- Set Group by to Meter.

Observe:

- Different meters (e.g., tokens, requests) and their associated costs.
- Any spikes that correlate with your earlier workshop exercises.

## Create budgets and alerts for AI workloads

You’ll now create a budget to avoid unexpected AI costs and configure alerts when spending crosses thresholds.

### Create a budget for the workshop resource group

- In the Azure portal, go to Cost Management.
- Under Cost Management, select Budgets under Monitoring on the left-hand side menu.
- Ensure the Scope is set to your workshop resource group.
- Select Add to create a new budget.  

Fill in:

- Name: `AIforITOps-Workshop-Budget`  
- Reset period: `Monthly`  
- Start date: Today (or the start of the current month)  
- Expiration date: A few months in the future  
- Budget amount: Choose a realistic limit for the lab (e.g., `50` in your local currency).
- Select Next.
- On the Alerts page, click the Type drop-down and select Actual cost.
- On the % of budget field, enter `80` to trigger an alert when spending reaches 80% of the budget.
- On the Alert recipients (email), type your e-mail address (or a shared workshop email) to receive notifications.
- Change the Language preference based on your own preference (e.g., English, Spanish, etc.).
- Click Create.

## Build a simple AI cost dashboard

To make ongoing monitoring easier, you can pin key cost views to a dashboard.

### Pin cost tiles to a dashboard

- Back to the Cost Management page, click Cost analysis, and configure a view as previously:
  - View: Daily costs.
  - Scope: workshop resource group.
  - Period: Last 7 days.
  - Filter: `Resource type` is `microsoft.cognitiveservices/accounts`
  - At the top of the chart, select Pin to dashboard.
- Choose an existing dashboard or create a new one (e.g., `AIforITOps-Cost-Dashboard`).

### Review your dashboard

- Return to the home page in the Azure portal.
- Click the Menu icon (three horizontal lines) in the top left corner and select Dashboard.
- On the top, left corner, change from My Dashboard to your AIforITOps-Cost-Dashboard
- Confirm that:
  - You can see AI-related costs over time.  
  - You can quickly identify which services are driving spend.

## What's next?

Bonus - [Bonus content](./Bonus.md).
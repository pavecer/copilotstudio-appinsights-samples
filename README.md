# Copilot Studio App Insights Monitoring Samples

KQL queries, an Azure Workbook, and alert rules for monitoring Copilot Studio agents in Teams channel traffic via Application Insights.

## Prerequisites

- A Copilot Studio agent connected to the **Teams** or **M365 Copilot** channel
- An **Application Insights** resource receiving telemetry from that agent
- Azure CLI (`az`) installed and logged in (`az login`)

## Contents

| Path | Description |
|---|---|
| `kql/01-latency-summary-24h.kql` | P50/P95/avg latency over 24 h |
| `kql/02-slowest-responses-24h.kql` | Top 10 slowest conversations |
| `kql/03-error-signals-7d.kql` | Failures and exceptions over 7 days |
| `kql/04-topic-scorecard-7d.kql` | Per-topic start/end/failure counts |
| `kql/05-live-traffic-2h.kql` | Near-real-time traffic in 5-minute bins |
| `workbook/copilotstudio-agent-monitoring.workbook.json` | Azure Workbook with all five panels |
| `alerts/alerts.bicep` | Two scheduled query alert rules (disabled by default) |

## Quick Start

### 1. Run KQL queries

Open any `.kql` file in the `kql/` folder and run it in the **Logs** blade of your Application Insights resource in the Azure portal. No changes needed — the queries are self-contained.

### 2. Import the Workbook

1. Open your Application Insights resource in the [Azure portal](https://portal.azure.com).
2. Navigate to **Workbooks** → **New** → **Advanced Editor** (the `</>` icon).
3. Paste the contents of `workbook/copilotstudio-agent-monitoring.workbook.json`.
4. Click **Apply**, then save the workbook.

> The workbook uses your Application Insights resource as the data source automatically when opened from within that resource's Workbooks blade.

### 3. Deploy Alert Rules

The Bicep template deploys two scheduled query alert rules. By default both are **disabled** (`enabled=false`) so you can review them before they fire.

**Get your Application Insights resource ID:**

```powershell
az monitor app-insights component show `
  --app <your-appinsights-name> `
  --resource-group <your-resource-group> `
  --query id -o tsv
```

**Deploy the alerts (dry run, disabled):**

```powershell
az deployment group create `
  --subscription <your-subscription-id> `
  --resource-group <your-resource-group> `
  --template-file alerts/alerts.bicep `
  --parameters appInsightsResourceId='<resource-id-from-above>' enabled=false actionGroupResourceIds='[]'
```

**Enable alerts and wire up an action group:**

```powershell
az deployment group create `
  --subscription <your-subscription-id> `
  --resource-group <your-resource-group> `
  --template-file alerts/alerts.bicep `
  --parameters appInsightsResourceId='<resource-id-from-above>' `
               enabled=true `
               actionGroupResourceIds='["/subscriptions/<sub>/resourceGroups/<rg>/providers/microsoft.insights/actionGroups/<ag-name>"]'
```

## Alert Rules Included

| Rule | Condition | Severity |
|---|---|---|
| `copilotstudio-latency-p95` | P95 response latency > 3000 ms over 15 min | 2 (Warning) |
| `copilotstudio-error-signals` | Combined failures/exceptions > 0 over 15 min | 1 (Error) |

Both rules evaluate every 5 minutes over a 15-minute window.

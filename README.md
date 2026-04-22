# Copilot Studio App Insights Monitoring Samples (Local Review)

This folder contains local-only samples for monitoring Copilot Studio agents in Teams channel traffic.
No deployment was executed.

## Contents

- `kql/01-latency-summary-24h.kql`
- `kql/02-slowest-responses-24h.kql`
- `kql/03-error-signals-7d.kql`
- `kql/04-topic-scorecard-7d.kql`
- `kql/05-live-traffic-2h.kql`
- `workbook/copilotstudio-agent-monitoring.workbook.json` (draft workbook definition)
- `alerts/alerts.bicep` (2 scheduled query alert rules, disabled by default)

## Alert Rules Included

1. `copilotstudio-latency-p95`
- Triggers when p95 response latency > 3000 ms over 15 minutes.

2. `copilotstudio-error-signals`
- Triggers when combined failures/exceptions > 0 over 15 minutes.

Both alerts are configured with `enabled = false` by default.

## Optional deployment command (do not run until approved)

```powershell
az deployment group create `
  --subscription ff6e6a8b-29f6-4666-b4b0-ff238c72bb23 `
  --resource-group pvecopstud `
  --template-file alerts/alerts.bicep `
  --parameters enabled=false actionGroupResourceIds='[]'
```

## Workbook import note

The workbook JSON is a local draft you can review and adjust first. After approval, we can convert/import it into Azure Workbooks.

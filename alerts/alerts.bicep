@description('Azure region for scheduled query rules. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Application Insights resource ID in scope')
param appInsightsResourceId string

@description('Action group resource IDs to notify. Keep empty for dry run.')
param actionGroupResourceIds array = []

@description('Do not enable until reviewed')
param enabled bool = false

resource latencyP95Alert 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = {
  name: 'copilotstudio-latency-p95'
  location: location
  kind: 'LogAlert'
  properties: {
    description: 'Copilot Studio response latency p95 is above threshold for Teams traffic.'
    displayName: 'Copilot Studio Latency P95 > 3000ms'
    enabled: enabled
    severity: 2
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [
      appInsightsResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'customEvents | where timestamp > ago(15m) | extend channelId=tostring(customDimensions["channelId"]) | where channelId in ("m365copilot","msteams","teams") | where name in ("BotMessageReceived","BotMessageSend") | summarize userTs=minif(timestamp, name=="BotMessageReceived"), botTs=minif(timestamp, name=="BotMessageSend") by operation_Id, session_Id | where isnotempty(userTs) and isnotempty(botTs) | extend latencyMs=datetime_diff("millisecond", botTs, userTs) | summarize p95=percentile(latencyMs,95)'
          timeAggregation: 'Average'
          metricMeasureColumn: 'p95'
          operator: 'GreaterThan'
          threshold: 3000
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: actionGroupResourceIds
      customProperties: {
        sample: 'local-review'
      }
    }
  }
}

resource errorSignalsAlert 'Microsoft.Insights/scheduledQueryRules@2023-12-01' = {
  name: 'copilotstudio-error-signals'
  location: location
  kind: 'LogAlert'
  properties: {
    description: 'Copilot Studio failures/exceptions detected in Teams traffic.'
    displayName: 'Copilot Studio Error Signals > 0'
    enabled: enabled
    severity: 1
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    scopes: [
      appInsightsResourceId
    ]
    criteria: {
      allOf: [
        {
          query: 'let eventFailures = toscalar(customEvents | where timestamp > ago(15m) | extend channelId=tostring(customDimensions["channelId"]) | where channelId in ("m365copilot","msteams","teams") | extend result=tolower(tostring(customDimensions["Result"])) | where result in ("failed","error","timeout","cancelled") or name has_any ("Error","Exception","Failure") | summarize count()); let exceptionCount = toscalar(exceptions | where timestamp > ago(15m) | summarize count()); print totalErrorSignals = coalesce(eventFailures, 0) + coalesce(exceptionCount, 0)'
          timeAggregation: 'Average'
          metricMeasureColumn: 'totalErrorSignals'
          operator: 'GreaterThan'
          threshold: 0
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    autoMitigate: true
    actions: {
      actionGroups: actionGroupResourceIds
      customProperties: {
        sample: 'local-review'
      }
    }
  }
}

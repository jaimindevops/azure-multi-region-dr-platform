@description('Resource prefix')
param prefix string

@description('Admin Notification Email')
param alertEmail string

@description('Slack Webhook URL')
@secure()
param slackWebhookUrl string = ''

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${prefix}-alerts'
  location: 'Global'
  properties: {
    groupShortName: 'DRAlerts'
    enabled: true
    emailReceivers: [
      {
        name: 'admin-alert'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: empty(slackWebhookUrl) ? [] : [
      {
        name: 'slack-alerts'
        serviceUri: slackWebhookUrl
        useCommonAlertSchema: true
      }
    ]
  }
}

resource activityAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'alert-aks-primary-health'
  location: 'Global'
  properties: {
    scopes: [
      resourceGroup().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'operationName'
          equals: 'Microsoft.ContainerService/managedClusters/write'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroup.id
        }
      ]
    }
    enabled: true
    description: 'Triggers Email and Slack alerts when primary AKS cluster changes state or is modified'
  }
}

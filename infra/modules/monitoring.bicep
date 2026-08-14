@description('Resource prefix')
param prefix string

@description('Admin Notification Email')
param alertEmail string

@description('Slack Inbound Channel Email Address')
param slackChannelEmail string = ''

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
      {
        name: 'SlackChannel'
        emailAddress: slackChannelEmail
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
    description: 'Triggers multi-channel alerts (Email & Slack) when primary AKS cluster changes state'
  }
}

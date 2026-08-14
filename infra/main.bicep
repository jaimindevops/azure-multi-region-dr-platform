targetScope = 'subscription'

@description('Deployment prefix')
param prefix string = 'dr'

@description('Admin Notification Email')
param alertEmail string = 'jaimincanada18@gmail.com'

@description('Slack Inbound Channel Email')
param slackChannelEmail string = ''

// 1. Primary Resource Group (East US)
resource rgPrimary 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${prefix}-primary-eastus'
  location: 'eastus'
}

// 2. Secondary DR Resource Group (West US)
resource rgSecondary 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${prefix}-secondary-westus'
  location: 'westus'
}

// 3. Multi-Channel Monitoring & Alerting
module actionGroup 'modules/monitoring.bicep' = {
  name: 'deployMonitoringAndAlerts'
  scope: rgPrimary
  params: {
    prefix: prefix
    alertEmail: alertEmail
    slackChannelEmail: slackChannelEmail
  }
}

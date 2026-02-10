@description('Location for all resources')
param location string = resourceGroup().location

@description('Default name for Azure Container App, and name prefix for all other resources')
param name string

@description('Azure Container App name')
param containerAppName string = name

@description('Environment name for the Container Apps Environment')
param environmentName string = '${name}-env'

@description('Number of CPU cores allocated to the container')
param cpuCores string = '0.5'

@description('Amount of memory allocated to the container')
param memorySize string = '1Gi'

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 3

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Whether to collect telemetry')
param azureMcpCollectTelemetry string

@description('Azure AD Tenant ID')
param azureAdTenantId string

@description('Azure AD Client ID')
param azureAdClientId string

@description('Azure AD authorization Server')
param azureAdInstance string

@description('Resource ID of the user-assigned managed identity')
param userAssignedManagedIdentityId string = ''

@description('Client ID of the user-assigned managed identity')
param userAssignedManagedIdentityClientId string = ''

@description('Azure AD Client Secret for OBO flow (stored as Container App secret)')
@secure()
param azureAdClientSecret string = ''

// Server args: expose ALL Azure MCP tools with On-Behalf-Of auth for full downstream API support
var serverArgs = [
  '--transport'
  'http'
  '--outgoing-auth-strategy'
  'UseOnBehalfOf'
  '--mode'
  'all'
]

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  properties: {}
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: {
    product: 'azmcp'
  }
  identity: !empty(userAssignedManagedIdentityId)
    ? {
        type: 'UserAssigned'
        userAssignedIdentities: {
          '${userAssignedManagedIdentityId}': {}
        }
      }
    : null
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      secrets: !empty(azureAdClientSecret) ? [
        {
          name: 'server-client-secret'
          value: azureAdClientSecret
        }
      ] : []
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        transport: 'http'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azure-sdk/azure-mcp:latest'
          name: containerAppName
          command: []
          args: serverArgs
          resources: {
            cpu: json(cpuCores)
            memory: memorySize
          }
          env: concat(
            [
              {
                name: 'ASPNETCORE_ENVIRONMENT'
                value: 'Production'
              }
              {
                name: 'ASPNETCORE_URLS'
                value: 'http://+:8080'
              }
              {
                name: 'AZURE_TOKEN_CREDENTIALS'
                value: 'managedidentitycredential'
              }
              {
                name: 'AZURE_MCP_INCLUDE_PRODUCTION_CREDENTIALS'
                value: 'true'
              }
              {
                name: 'AZURE_MCP_COLLECT_TELEMETRY'
                value: azureMcpCollectTelemetry
              }
              {
                name: 'AzureAd__Instance'
                value: azureAdInstance
              }
              {
                name: 'AzureAd__TenantId'
                value: azureAdTenantId
              }
              {
                name: 'AzureAd__ClientId'
                value: azureAdClientId
              }
              {
                name: 'AZURE_CLIENT_ID'
                value: userAssignedManagedIdentityClientId
              }
              {
                name: 'AZURE_LOG_LEVEL'
                value: 'Verbose'
              }
            ],
            !empty(azureAdClientSecret)
              ? [
                  {
                    name: 'AzureAd__ClientSecret'
                    secretRef: 'server-client-secret'
                  }
                ]
              : [],
            !empty(appInsightsConnectionString)
              ? [
                  {
                    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                    value: appInsightsConnectionString
                  }
                ]
              : []
          )
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaler'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppResourceId string = containerApp.id
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output containerAppName string = containerApp.name
output containerAppEnvironmentId string = containerAppsEnvironment.id

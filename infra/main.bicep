@description('Location for all resources')
param location string = resourceGroup().location

@description('Name for the Azure Container App')
param acaName string

@description('Display name for the Server Entra App')
param entraAppServerDisplayName string

@description('Display name for the Client Entra App')
param entraAppClientDisplayName string

@description('Application Insights connection string. Use "DISABLED" to disable telemetry, or provide existing connection string. If omitted, new App Insights will be created.')
param appInsightsConnectionString string = ''

@description('Client secret for the server Entra App (required for OBO auth flow)')
@secure()
param serverClientSecret string = ''

// Deploy Application Insights if appInsightsConnectionString is empty and not DISABLED
var appInsightsName = '${acaName}-insights'

module appInsights 'modules/application-insights.bicep' = {
  name: 'application-insights-deployment'
  params: {
    appInsightsConnectionString: appInsightsConnectionString
    name: appInsightsName
    location: location
  }
}

// Deploy Entra App (Client) first — server needs its ID for pre-authorization
var entraAppClientUniqueName = '${replace(toLower(entraAppClientDisplayName), ' ', '-')}-${uniqueString(resourceGroup().id)}'
module entraAppClient 'modules/entra-app.bicep' = {
  name: 'entra-app-client-deployment'
  params: {
    entraAppDisplayName: entraAppClientDisplayName
    entraAppUniqueName: entraAppClientUniqueName
    isServer: false
  }
}

// Deploy Entra App (Server) — with downstream API permissions and pre-authorized client
var entraAppServerUniqueName = '${replace(toLower(entraAppServerDisplayName), ' ', '-')}-${uniqueString(resourceGroup().id)}'
module entraAppServer 'modules/entra-app.bicep' = {
  name: 'entra-app-server-deployment'
  params: {
    entraAppDisplayName: entraAppServerDisplayName
    entraAppUniqueName: entraAppServerUniqueName
    isServer: true
    entraAppScopeValue: 'Mcp.Tools.ReadWrite'
    entraAppScopeDisplayName: 'Azure MCP Tools ReadWrite'
    entraAppScopeDescription: 'Permission to call all Azure MCP tools'
    knownClientAppId: entraAppClient.outputs.entraAppClientId
  }
}

// Deploy managed identity for Azure MCP Server
module acaManagedIdentity 'modules/aca-managed-identity.bicep' = {
  name: 'aca-managed-identity-deployment'
  params: {
    location: location
    managedIdentityName: '${acaName}-managed-identity'
  }
}

// Deploy ACA Infrastructure to host Azure MCP Server with ALL Azure tools
module acaInfrastructure 'modules/aca-infrastructure.bicep' = {
  name: 'aca-infrastructure-deployment'
  params: {
    name: acaName
    location: location
    appInsightsConnectionString: appInsights.outputs.connectionString
    azureMcpCollectTelemetry: string(!empty(appInsights.outputs.connectionString))
    azureAdTenantId: tenant().tenantId
    azureAdClientId: entraAppServer.outputs.entraAppClientId
    azureAdInstance: environment().authentication.loginEndpoint
    userAssignedManagedIdentityId: acaManagedIdentity.outputs.managedIdentityId
    userAssignedManagedIdentityClientId: acaManagedIdentity.outputs.managedIdentityClientId
    azureAdClientSecret: serverClientSecret
  }
}

// Assign Contributor role to managed identity at subscription level
module acaRoleAssignment 'modules/aca-subscription-role.bicep' = {
  name: 'aca-subscription-role-deployment'
  scope: subscription()
  params: {
    managedIdentityPrincipalId: acaManagedIdentity.outputs.managedIdentityPrincipalId
  }
}

// Outputs for azd and other consumers
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output AZURE_LOCATION string = location

// Entra App outputs
output ENTRA_APP_SERVER_CLIENT_ID string = entraAppServer.outputs.entraAppClientId
output ENTRA_APP_SERVER_SCOPE_ID string = entraAppServer.outputs.entraAppScopeId
output ENTRA_APP_SERVER_SCOPE_VALUE string = entraAppServer.outputs.entraAppScopeValue
output ENTRA_APP_CLIENT_CLIENT_ID string = entraAppClient.outputs.entraAppClientId

// ACA Infrastructure outputs
output CONTAINER_APP_URL string = acaInfrastructure.outputs.containerAppUrl
output CONTAINER_APP_NAME string = acaInfrastructure.outputs.containerAppName
output AZURE_CONTAINER_APP_ENVIRONMENT_ID string = acaInfrastructure.outputs.containerAppEnvironmentId

// ACA user assigned managed identity
output CONTAINER_APP_MANAGED_IDENTITY_CLIENT_ID string = acaManagedIdentity.outputs.managedIdentityClientId

// Application Insights outputs
output APPLICATION_INSIGHTS_NAME string = appInsightsName
output APPLICATION_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_MCP_COLLECT_TELEMETRY string = string(!empty(appInsights.outputs.connectionString))

/*
  Creates an Entra (Azure AD) application with the necessary components
  for secure authentication and authorization.

  Server app:
    - Exposes API scope (Mcp.Tools.ReadWrite) for OAuth 2.0 authentication
    - Configures identifierUris for proper OAuth token audience
    - Declares requiredResourceAccess for all downstream Azure APIs
    - Pre-authorizes the client app to skip consent prompts

  Client app:
    - Used by Power Apps custom connector to connect to the MCP server
    - Requests the server app's Mcp.Tools.ReadWrite scope
*/

extension microsoftGraphV1

@description('Display name for the Entra Application')
param entraAppDisplayName string

@description('Unique name for the Entra Application')
param entraAppUniqueName string

param isServer bool

@description('Value of the app scope')
param entraAppScopeValue string = ''

@description('Display name of the app scope')
param entraAppScopeDisplayName string = ''

@description('Description of the app scope')
param entraAppScopeDescription string = ''

@description('Known client app id')
param knownClientAppId string = ''

@description('Server app client ID (used by client app to request API permissions)')
param serverAppClientId string = ''

var scopeId = guid(entraAppUniqueName, entraAppScopeValue)

// Downstream API permissions required by Azure MCP Server for all Azure services
// See: https://github.com/microsoft/mcp/blob/main/servers/Azure.Mcp.Server/azd-templates/api-permissions.md
var serverRequiredResourceAccess = [
  // Azure Resource Manager (ARM) — used by most Azure tools
  {
    resourceAppId: '797f4846-ba00-4fd7-ba43-dac1f8f63013'
    resourceAccess: [
      {
        id: '41094075-9dad-400e-a0bd-54e686782033' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure Storage
  {
    resourceAppId: 'e406a681-f3d4-42a8-90b6-c2b029497af1'
    resourceAccess: [
      {
        id: '03e0da56-190b-40ad-a80c-ea378c433f7f' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure Key Vault
  {
    resourceAppId: 'cfa8b339-82a2-471a-a3c9-0fc0be7a4093'
    resourceAccess: [
      {
        id: 'f53da476-18e3-4152-8e01-aec403e6edc0' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure Data Explorer (Kusto)
  {
    resourceAppId: '2746ea77-4702-4b45-80ca-3c97e680e8b7'
    resourceAccess: [
      {
        id: '00d678f0-da44-4b12-a6d6-c98bcfd1c5fe' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure OSS RDBMS AAD (PostgreSQL/MySQL)
  {
    resourceAppId: '123cd850-d9df-40bd-94d5-c9f07b7fa203'
    resourceAccess: [
      {
        id: 'cef99a3a-4cd3-4408-8143-4375d1e38a17' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure CLI Extension (CLI Generate)
  {
    resourceAppId: 'a5ede409-60d3-4a6c-93e6-eb2e7271e8e3'
    resourceAccess: [
      {
        id: '94f3aa7c-b710-40be-83e4-8b5de364a323' // Azclis.Intelligent.All
        type: 'Scope'
      }
    ]
  }
  // Azure App Configuration
  {
    resourceAppId: '35ffadb3-7fc1-497e-b61b-381d28e744cc'
    resourceAccess: [
      {
        id: '8d17f7f7-030c-4b57-8129-cfb5a16433cd' // KeyValue.Read
        type: 'Scope'
      }
      {
        id: '77967a14-4f88-4960-84da-e8f71f761ac2' // KeyValue.Write
        type: 'Scope'
      }
      {
        id: '08eeff12-9b4a-4273-b3d9-ff8a13c32645' // KeyValue.Delete
        type: 'Scope'
      }
      {
        id: '5970d132-a862-421f-9352-8ed18f833d78' // Snapshot.Read
        type: 'Scope'
      }
      {
        id: 'ea601552-5fd3-4792-9dfc-e85be5a6827c' // Snapshot.Write
        type: 'Scope'
      }
      {
        id: '28bb462a-d940-4cbe-afeb-281756df9af8' // Snapshot.Action
        type: 'Scope'
      }
    ]
  }
  // Azure Event Hubs
  {
    resourceAppId: '80369ed6-5f11-4dd9-bef3-692475845e77'
    resourceAccess: [
      {
        id: '7d388411-3845-4cfc-aa69-33192f4b9735' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure Service Bus
  {
    resourceAppId: '80a10ef9-8168-493d-abf9-3297c4ef6e3c'
    resourceAccess: [
      {
        id: '40e16207-c5fd-4916-8ca4-64565f2367ca' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure AI Search
  {
    resourceAppId: '880da380-985e-4198-81b9-e05b1cc53158'
    resourceAccess: [
      {
        id: 'a4165a31-5d9e-4120-bd1e-9d88c66fd3b8' // user_impersonation
        type: 'Scope'
      }
    ]
  }
  // Azure Cognitive Services (Speech)
  {
    resourceAppId: '7d312290-28c8-473c-a0ed-8e53749b6d6d'
    resourceAccess: [
      {
        id: '5f1e8914-a52b-429f-9324-91b92b81adaf' // user_impersonation
        type: 'Scope'
      }
    ]
  }
]

// Client app needs permission to access the server app's scope
var clientRequiredResourceAccess = !empty(serverAppClientId)
  ? [
      {
        resourceAppId: serverAppClientId
        resourceAccess: [
          {
            id: guid(entraAppUniqueName, 'Mcp.Tools.ReadWrite')
            type: 'Scope'
          }
        ]
      }
    ]
  : []

resource entraApp 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: entraAppUniqueName
  displayName: entraAppDisplayName
  signInAudience: 'AzureADMyOrg'
  api: isServer
    ? {
        oauth2PermissionScopes: [
          {
            id: scopeId
            type: 'User'
            adminConsentDescription: entraAppScopeDescription
            adminConsentDisplayName: entraAppScopeDisplayName
            userConsentDescription: entraAppScopeDescription
            userConsentDisplayName: entraAppScopeDisplayName
            value: entraAppScopeValue
            isEnabled: true
          }
        ]
        preAuthorizedApplications: [
          {
            appId: knownClientAppId
            delegatedPermissionIds: [
              scopeId
            ]
          }
        ]
        requestedAccessTokenVersion: 2
      }
    : null
  requiredResourceAccess: isServer ? serverRequiredResourceAccess : clientRequiredResourceAccess
}

// Create service principal for the app registration
resource entraAppServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: entraApp.appId
}

output entraAppClientId string = entraApp.appId
output entraAppObjectId string = entraApp.id
output entraAppServicePrincipalId string = entraAppServicePrincipal.id
output entraAppIdentifierUri string = 'api://${entraApp.appId}'
output entraAppScopeValue string = entraAppScopeValue
output entraAppScopeId string = isServer ? entraApp.api.oauth2PermissionScopes[0].id : ''

/*
  Creates an Entra (Azure AD) application with the necessary components
  for secure authentication and authorization.

  Server app:
    - Exposes API scope (Mcp.Tools.ReadWrite) for OAuth 2.0 authentication
    - Pre-authorizes the client app to skip consent prompts

  Client app:
    - Used by Power Apps custom connector to connect to the MCP server

  NOTE: Downstream API permissions (ARM, Storage, Key Vault, etc.) are added
  via the post-deployment script: scripts/setup-permissions.ps1 or .sh
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

var scopeId = guid(entraAppUniqueName, entraAppScopeValue)

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
}

output entraAppClientId string = entraApp.appId
output entraAppObjectId string = entraApp.id
output entraAppIdentifierUri string = 'api://${entraApp.appId}'
output entraAppScopeValue string = entraAppScopeValue
output entraAppScopeId string = isServer ? entraApp.api.oauth2PermissionScopes[0].id : ''

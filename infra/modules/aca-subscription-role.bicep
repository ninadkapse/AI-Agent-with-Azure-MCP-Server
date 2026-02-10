targetScope = 'subscription'

@description('The principal ID of the managed identity to assign the role to')
param managedIdentityPrincipalId string

@description('The role definition ID to assign. Defaults to the built-in Contributor role (b24988ac-6180-42a0-ab88-20f7382dd24c)')
param roleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

// Create Contributor role assignment at subscription level to enable all Azure operations
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().subscriptionId, managedIdentityPrincipalId, roleDefinitionId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = roleAssignment.id
output roleAssignmentName string = roleAssignment.name

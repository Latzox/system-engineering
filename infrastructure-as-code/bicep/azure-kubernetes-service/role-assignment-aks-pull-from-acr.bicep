@description('Role definition ID for ACR pull role')
param roleDefinitionId string

@secure()
param managedIdentityPrincipalId string

@description('Role assignment for managed identity to pull images from ACR')
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, roleDefinitionId)
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: managedIdentityPrincipalId
  }
}

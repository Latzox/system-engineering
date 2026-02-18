// Use targetScope to tell Bicep that the resources are for a specific scope
targetScope = 'managementGroup'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'policyDefinition'
  // Params ...
}

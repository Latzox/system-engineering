// Use targetScope to tell Bicep that the resources are for a specific scope
targetScope = 'tenant'

// Define the resource which should be deployed on tenant level
resource managementGroup 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'operations'
  properties: {
    displayName: 'Operations'
  }
}

// Define another resource which should be deployed on tenant level
resource managementGroup2 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: 'production'
  properties: {
    displayName: 'Production'
    details: {
      parent: {
        id: managementGroup.id
      }
    }
  }
}

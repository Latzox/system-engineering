// Use targetScope to tell Bicep that the resources are for a specific scope
targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-proj-dev-001'
  location: 'switzerlandnorth'
}

// Use targetScope to tell Bicep that the resources are for a specific scope
targetScope = 'subscription'

module sa 'br:latzo.azurecr.io/bicep/modules/storage/private-blob:1.0.0' = {
  name: 'storage-deployment'
  // Use the scope inside the resource to tell bicep that this resource has a different targetScope - This mostly only works with modules
  scope: resourceGroup('rg-proj-dev-001')
  params: {
    accessTier: 'Hot'
    storageAccountName: 'saprojdev001'
    containerName: 'images'
    storageKind: 'StorageV2'
  }
}

// To deploy a resource into another subscription, add it to the scope as a second argument.
module sa2 'br:latzo.azurecr.io/bicep/modules/storage/private-blob:1.0.0' = {
  name: 'storage-deployment2'
  // Include the target subscription ID and the resource group
  scope: resourceGroup('f0750bbe-ea75-4ae5-b24d-a92ca601da2c', 'rg-storage-dev-002')
  params: {
    accessTier: 'Hot'
    storageAccountName: 'saprojdev002'
    containerName: 'images'
    storageKind: 'StorageV2'
  }
}

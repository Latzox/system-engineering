// Definition of the main resource
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'myStorageAccount'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Definition of an extension resource: Resource Lock
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  // Use the scope property to attach the lock to the main resource
  scope: sa
  name: 'storageAccountLock'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents deletion of the storage account.'
  }
}

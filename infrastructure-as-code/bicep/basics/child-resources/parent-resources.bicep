// Definition of the main resource: Storage account
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'myStorageAccount'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Definition of the blob service resource within the storage account
resource blobservice 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  // Establishing the relationship with the storage account
  parent: sa
  name: 'default'
}

// Definition of the blob container resource within the blob service
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  // Establishing the relationship with the blob service
  parent: blobservice
  name: 'images'
}

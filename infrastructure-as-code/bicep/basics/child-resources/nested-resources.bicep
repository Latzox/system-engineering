// Definition of the main resource
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'myStorageAccount'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  
  // Nested resource: Blob service within the storage account
  resource blobservice 'blobServices@2023-05-01' = {
    name: 'default'

    // Nested resource: Blob container within the blob service
    resource container 'containers@2023-05-01' = {
      name: 'images'
    }
  }
}

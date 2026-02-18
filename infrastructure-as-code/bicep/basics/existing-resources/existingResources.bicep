// Use "existing" to tell bicep that this resource already exisits
resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: 'myStorageAccount'
}

// -------------------------------------------------------------------------------

// You can refer to resources in other resource groups as well
resource sa2 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  scope: resourceGroup('myResourceGroup')
  name: 'myStorageAccount'
}

// -------------------------------------------------------------------------------

// Or refer to resources which are in another subscription
resource sa3 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  scope: resourceGroup('A123b4567c-1234-1a2b-2b1a-1234abc12345', 'myResourceGroup')
  name: 'myStorageAccount'
}

// -------------------------------------------------------------------------------

// We can create a child resource within an already existing resource
resource blobservice 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: sa
  name: 'default'
}

// --------------------------------------------------------------------------------

// The same works for extensions for existing resources
resource sa4 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: 'myStorageAccount'
}

// Definition of an extension resource
resource lock 'Microsoft.Authorization/locks@2020-05-01' = {
  // Use the scope property to attach the lock to the existing main resource
  scope: sa4
  name: 'storageAccountLock'
  properties: {
    level: 'CanNotDelete'
    notes: 'Prevents deletion of the storage account.'
  }
}

// -------------------------------------------------------------------------------

// Use properties from existing resources
resource sa5 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: 'myStorageAccount'
}

resource fa 'Microsoft.Web/sites@2023-12-01' = {
  name: 'functionapp'
  location: resourceGroup().location
  properties: {
    siteConfig: {
       appSettings: [
        {
          name: 'StorageAccountKey'
          // Refer to the properties of the existing resource
          value: sa5.listKeys().keys[0].value
        }
       ]
    }
  }
}

@description('Takes the location of the already existing resource group.')
param location string = resourceGroup().location

// Azure Storage Account with public access limited to swp office ip address
resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'swpartifacts'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      ipRules: [
        {
          action: 'Allow'
          value: '212.51.140.246'
        }
      ]
      defaultAction: 'Deny'
    }
    allowBlobPublicAccess: true
  }
}

// Blob Container with public access for jtt-uat
resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${sa.name}/default/jtt-uat'
  properties: {
    publicAccess: 'Blob'
  } 
}

// Blob Container with public access for jtt-prd
resource container2 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${sa.name}/default/jtt-prd'
  properties: {
    publicAccess: 'Blob'
  } 
}

@description('Takes the location of the already existing resource group.')
param location string = resourceGroup().location

resource sa 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: 'latzoimages'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource fs 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${sa.name}/default/images'
  properties: {
    accessTier: 'Hot'
    shareQuota: 50
  }
}

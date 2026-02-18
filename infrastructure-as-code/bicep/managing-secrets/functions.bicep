// Parameters
@description('The name of the resource.')
param resName string

@description('The location for the resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('The connection string for the Cosmos DB Table API.')
@secure()
param COSMOS_TABLEAPI_CONNECTION_STRING string

// Cleaned resource name to remove hyphens
var resNameCleaned = replace(resName, '-', '')

// Storage Account Resource
resource sa 'Microsoft.Storage/storageAccounts@2023-04-01' = {
  name: 'sa${resNameCleaned}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

// App Service Plan Resource
resource asp 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-${resName}'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

// Function App Resource
resource fa 'Microsoft.Web/sites@2023-12-01' = {
  name: 'fa-${resName}'
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    serverFarmId: asp.id
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${sa.name};EndpointSuffix=core.windows.net;AccountKey=${sa.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'COSMOS_TABLEAPI_CONNECTION_STRING'
          value: COSMOS_TABLEAPI_CONNECTION_STRING
        }
      ]
      cors: {
        allowedOrigins: [
          '*'
        ]
      }
    }
    httpsOnly: true
  }
}

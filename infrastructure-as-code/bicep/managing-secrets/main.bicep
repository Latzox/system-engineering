// Parameters
@description('The name of the resource. Default is secrets-test-001')
param resName string = 'secrets-dev-001'

@description('The id of the user who needs to access the keyvault.')
param objectId string

// Deploy the CosmosDB and Key Vault resources using the cosmosdb-keyvault.bicep module
module cosmosdb 'cosmosdb-keyvault.bicep' = {
  name: 'db-deployment'
  params: {
    resName: resName
    objectId: objectId
  }
}

// Reference the existing Key Vault resource
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: cosmosdb.outputs.kvName
}

// Deploy the Function App resources using the functions.bicep module
module functions 'functions.bicep' = {
  name: 'functions-deployment'
  params: {
    // Retrieve the secret from the Key Vault
    COSMOS_TABLEAPI_CONNECTION_STRING: keyvault.getSecret(cosmosdb.outputs.secretName)
    resName: resName
  }
}

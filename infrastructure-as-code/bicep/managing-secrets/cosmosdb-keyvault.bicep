// Parameters
@description('The name of the resource.')
param resName string

@description('The id of the user who needs to access the keyvault.')
param objectId string

@description('The location for the resources. Defaults to the resource group location.')
param location string = resourceGroup().location

// Cleaned resource name to remove hyphens
var resNameCleaned = replace(resName, '-', '')

// Cosmos DB Account Resource
resource cosmosdbaccount 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: 'cda-${resName}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    capabilities: [
      {
        name: 'EnableTable'
      }
      {
        name: 'EnableServerless'
      }
    ]
    locations: [
      {
        locationName: 'Switzerland North'
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
  }
}

// Cosmos DB Table Resource
resource tabledb 'Microsoft.DocumentDB/databaseAccounts/tables@2016-03-31' = {
  parent: cosmosdbaccount
  name: 'visitorCounts'
  properties: {
    resource: {
      id: 'visitorCounts'
    }
  }
}

// Key Vault Resource
resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv${resNameCleaned}'
  location: location
  properties: {
    enabledForTemplateDeployment: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: objectId
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'list'
          ]
          secrets: [
            'list'
          ]
        }
      }
    ]
  }
}

// Key Vault Secret Resource
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyvault
  name: 'secret-${resName}'
  properties: {
    value: '${cosmosdbaccount.listConnectionStrings().connectionStrings[0].connectionString}'
  }
}

// Outputs
output kvName string = keyvault.name
output secretName string = secret.name

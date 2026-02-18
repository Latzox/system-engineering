@description('The name of the SQL logical server.')
param serverName string

@description('The name of the SQL Database.')
param sqlDBName string

@description('Location for all resources.')
param location string

@description('The tenant id')
param tenantId string

@description('The name of the sql server admin.')
param sqlAdminName string

@description('The entra object id of the sql server admin.')
param sqlAdminObjectId string

@description('The user type of the sql server admin.')
param principalType string

@description('The azureADOnlyAuthentication of the sql server admin.')
param azureADOnlyAuthentication bool

@description('The sku name of the sql database.')
param sqlDBSkuName string

@description('The sku tier of the sql database.')
param sqlDBSkuTier string

@description('The capacity of the sql database.')
param capacity int

resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: serverName
  location: location
  tags: {
    workload: 'Sample Backend with SQL Database'
    topic: 'SQL Server'
    environment: 'Production'
  }
  properties: {
    minimalTlsVersion: '1.2'
    administrators: {
      administratorType: 'ActiveDirectory'
      login: sqlAdminName
      sid: sqlAdminObjectId
      tenantId: tenantId
      principalType: principalType
      azureADOnlyAuthentication: azureADOnlyAuthentication
    }
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDBName
  location: location
  sku: {
    name: sqlDBSkuName
    tier: sqlDBSkuTier
    capacity: capacity
  }
}

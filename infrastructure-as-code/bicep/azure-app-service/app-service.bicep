@description('The region in which to deploy the resources')
param location string = resourceGroup().location

@description('The base name of the web application')
param applicationName string

@description('The SKU for the App Service Plan.')
param aspSkuName string

@description('The Docker image to deploy to the api')
param dockerImage string

@description('The name of the SQL Server to use')
param sqlServerName string

@description('The name of the SQL Database to connect to')
param sqlDatabaseName string

@description('The tags to apply to the resources')
param tags object = {
  workload: 'Sample Backend with SQL Database'
  topic: 'Backend'
  environment: 'Production'
}

@description('Deploy an app service plan for each region specified')
resource appServicePlans 'Microsoft.Web/serverfarms@2023-12-01' =  {
  name: 'asp-${applicationName}'
  location: location
  tags: tags
  kind: 'linux'
  properties: {
    reserved: true
  }	
  sku: {
    name: aspSkuName
  }
}

@description('Deploy a web application for each region specified')
resource webApp 'Microsoft.Web/sites@2023-12-01' =  {
  name: 'app-${applicationName}'
  location: location
  kind: 'app,linux,container'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      minTlsVersion: '1.3'
      http20Enabled: true
      linuxFxVersion: 'DOCKER|${dockerImage}'
      appSettings: [
        {
          name: 'SQL_SERVER'
          value: sqlServerName
        }
        {
          name: 'SQL_DATABASE'
          value: sqlDatabaseName
        }
      ]
    }
    httpsOnly: true
    clientAffinityEnabled: false
    serverFarmId: appServicePlans.id
  }
}

resource webAppConfig 'Microsoft.Web/sites/config@2023-12-01' = {
  parent: webApp
  name: 'web'
  properties: {
    acrUseManagedIdentityCreds: true
    acrUserManagedIdentityID: webApp.identity.principalId
  }
}

output managedIdentityPrincipalId string = webApp.identity.principalId

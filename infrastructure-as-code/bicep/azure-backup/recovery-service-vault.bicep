@description('Takes the location of the already existing resource group.')
param location string = resourceGroup().location

resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2023-08-01' = {
  name: 'ltz-backupvault'
  location: location
  tags: {
    environment: 'prod'
    owner: 'latzo'
    usage: 'backup vault'
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

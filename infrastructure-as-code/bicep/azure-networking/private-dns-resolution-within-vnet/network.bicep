@description('VNet name')
param vnetName string

@description('Address prefix')
param vnetAddressPrefix string

@description('Subnet 1 Prefix')
param subnet1Prefix string

@description('Subnet 1 Name')
param subnet1Name string

@description('Subnet 2 Prefix')
param subnet2Prefix string

@description('Subnet 2 Name')
param subnet2Name string

@description('Location for all resources.')
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

resource subnet1 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: subnet1Name
  parent: vnet
  properties: {
    addressPrefix: subnet1Prefix
  }
}

resource subnet2 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' = {
  name: subnet2Name
  parent: vnet
  properties: {
    addressPrefix: subnet2Prefix
  }
}

output subnet1Id string = subnet1.id
output subnet2Id string = subnet2.id
output vnetId string = vnet.id

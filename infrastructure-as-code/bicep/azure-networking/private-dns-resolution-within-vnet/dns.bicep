@description('Name of private dns zone.')
param dnszone string

@description('Dns zone vnet link name.')
param dnsVnetLinkName string

@description('VnetId')
param vnetId string

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: dnszone
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: dnsVnetLinkName
  location: 'Global'
  parent: dns
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vnetId
    }
  }
}

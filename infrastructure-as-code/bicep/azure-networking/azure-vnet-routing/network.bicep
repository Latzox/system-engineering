// Parameters
param location string = resourceGroup().location
param hubVnetName string = 'vnet-hub-routing-dev-001'
param spokeVnet1Name string = 'vnet-a-routing-dev-001'
param spokeVnet2Name string = 'vnet-b-routing-dev-001'
param hubVnetAddressPrefix string = '10.5.0.0/16'
param spokeVnet1AddressPrefix string = '10.6.0.0/16'
param spokeVnet2AddressPrefix string = '10.7.0.0/16'
param firewallSubnetPrefix string = '10.5.1.0/24'
param vmSubnetPrefix string = '10.5.2.0/24'
param bastionSubnetPrefix string = '10.5.3.0/27'
param spokeVnet1SubnetPrefix string = '10.6.1.0/24'
param spokeVnet2SubnetPrefix string = '10.7.1.0/24'

// Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
      {
        name: 'vmSubnet'
        properties: {
          addressPrefix: vmSubnetPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

// Spoke VNet 1
resource spokeVnet1 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVnet1Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnet1AddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: spokeVnet1SubnetPrefix
        }
      }
    ]
  }
}

// Spoke VNet 2
resource spokeVnet2 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: spokeVnet2Name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnet2AddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: spokeVnet2SubnetPrefix
        }
      }
    ]
  }
}

// Virtual Network Peering - Hub to Spoke1
resource hubToSpoke1Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: 'hub-to-spoke1'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Virtual Network Peering - Spoke1 to Hub
resource spoke1ToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: 'spoke1-to-hub'
  parent: spokeVnet1
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Virtual Network Peering - Hub to Spoke2
resource hubToSpoke2Peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: 'hub-to-spoke2'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet2.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Virtual Network Peering - Spoke2 to Hub
resource spoke2ToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: 'spoke2-to-hub'
  parent: spokeVnet2
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: '${hubVnetName}-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Bastion Host
resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: '${hubVnetName}-bastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIPConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetName, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${hubVnetName}-bastion-pip')
          }
        }
      }
    ]
  }
}

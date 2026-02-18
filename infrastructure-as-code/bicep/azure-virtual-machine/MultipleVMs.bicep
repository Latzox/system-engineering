param location string = resourceGroup().location
param vmSize string = 'Standard_D2s_v3'
param adminUsername string
@secure()
param adminPassword string

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'nsg-kali'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          description: 'Allow RDP access from any source'
        }
      }
      {
        name: 'AllowSSH'
        properties: {
          priority: 1010
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          description: 'Allow SSH access from any source'
        }
      }
      {
        name: 'AllowVNC'
        properties: {
          priority: 1020
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5901'
          description: 'Allow VNC access from any source'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: 'vnet-kali'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-11-01' = [for i in range(1,2): {
  name: 'publicIP-kali-${i}'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = [for i in range(1,2): {
  name: 'nic-kali-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIP[i-1].id
          }
        }
      }
    ]
  }
}]

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = [for i in range(1,2): {
  name: 'vm-kali-${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'kali-linux'
        offer: 'kali'
        sku: 'kali-2023-3'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: 'vm-kali-${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface[i-1].id
        }
      ]
    }
  }
  plan: {
    name: 'kali-2023-3'
    publisher: 'kali-linux'
    product: 'kali'
  }

  dependsOn: [
    networkInterface
  ]
}]

output vmPublicIPs array = [for i in range(1,2): {
  vmName: virtualMachine[i-1].name
  publicIP: publicIP[i-1].properties.ipAddress
}]

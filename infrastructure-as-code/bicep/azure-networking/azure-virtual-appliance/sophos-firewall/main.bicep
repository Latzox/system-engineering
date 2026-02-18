@description('Name of the Sophos Firewall VM')
param vmName string

@description('Admin Username')
param adminUsername string

@description('Admin Password')
@secure()
param adminPassword string

@description('Size of the VM')
param vmSize string = 'Standard_D2s_v3'

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Address prefix for the Virtual Network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Address prefix for the Subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Name of the Virtual Network')
param vnetName string = '${vmName}-vnet'

@description('Name of the Subnet')
param subnetName string = 'default'

@description('Public IP address name')
param publicIpName string = '${vmName}-pip'

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

resource sophosVM 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'sophos'
        offer: 'sophos-xg'
        sku: 'byol'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output publicIp string = publicIP.properties.ipAddress

// Parameters
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string

param hubVnetName string = 'vnet-hub-routing-dev-001'
param hubVmSubnetName string = 'vmSubnet'

param spokeVnet1Name string = 'vnet-a-routing-dev-001'
param spokeVnet1SubnetName string = 'default'

param spokeVnet2Name string = 'vnet-b-routing-dev-001'
param spokeVnet2SubnetName string = 'default'

param hubVmName string = 'hubVm'
param spokeVm1Name string = 'spokeVm1'
param spokeVm2Name string = 'spokeVm2'

// Hub VM Configuration
resource hubVmNic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${hubVmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetName, hubVmSubnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource hubVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: hubVmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: hubVmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: hubVmNic.id
        }
      ]
    }
  }
}

// Spoke 1 VM Configuration
resource spokeVm1Nic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${spokeVm1Name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnet1Name, spokeVnet1SubnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource spokeVm1 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: spokeVm1Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: spokeVm1Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spokeVm1Nic.id
        }
      ]
    }
  }
}

// Spoke 2 VM Configuration
resource spokeVm2Nic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${spokeVm2Name}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnet2Name, spokeVnet2SubnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource spokeVm2 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: spokeVm2Name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    osProfile: {
      computerName: spokeVm2Name
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: spokeVm2Nic.id
        }
      ]
    }
  }
}

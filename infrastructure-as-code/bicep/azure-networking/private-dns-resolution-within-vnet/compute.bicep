@description('Location for all resources.')
param location string = resourceGroup().location

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('VM names')
param vmNames array

@description('VM computer names')
param vmComputerNames array

@description('NIC names')
param nicNames array

@description('NSG names')
param nsgNames array

@description('Public IP names')
param pipNames array

@description('Unique DNS Names for the Public IPs')
param dnsLabelPrefixes array

@description('Subnet Ids for VMs')
param subnetIds array

@description('Size of the virtual machines.')
param vmSize string

@description('Allocation method for the Public IPs.')
@allowed([
  'Dynamic'
  'Static'
])
param pipAllocationMethod string

@description('SKU for the Public IPs.')
@allowed([
  'Basic'
  'Standard'
])
param pipSku string

@description('Security Type of the Virtual Machines.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}

resource nsgs 'Microsoft.Network/networkSecurityGroups@2024-01-01' = [for i in range(0, length(vmNames)): {
  name: nsgNames[i]
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '212.51.140.246'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}]

resource pips 'Microsoft.Network/publicIPAddresses@2024-01-01' = [for i in range(0, length(vmNames)): {
  name: pipNames[i]
  location: location
  sku: {
    name: pipSku
  }
  properties: {
    publicIPAllocationMethod: pipAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefixes[i]
    }
  }
}]

resource nics 'Microsoft.Network/networkInterfaces@2024-01-01' = [for i in range(0, length(vmNames)): {
  name: nicNames[i]
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pips[i].id
          }
          subnet: {
            id: subnetIds[i]
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgs[i].id
    }
  }
}]

resource vms 'Microsoft.Compute/virtualMachines@2024-03-01' = [for i in range(0, length(vmNames)): {
  name: vmNames[i]
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-11'
        sku: 'win11-23h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
    osProfile: {
      adminUsername: adminUsername
      adminPassword: adminPassword
      computerName: vmComputerNames[i]
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}]

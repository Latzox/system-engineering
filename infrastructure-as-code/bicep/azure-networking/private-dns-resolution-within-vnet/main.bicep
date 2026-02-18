// Parameters for network module
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

// Parameters for dns module
@description('Name of private dns zone.')
param dnszone string

@description('Dns zone vnet link name.')
param dnsVnetLinkName string

// Parameters for compute module
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

// Resource section
module network 'network.bicep' = {
  name: 'network-deployment'
  params: {
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnet1Prefix: subnet1Prefix
    subnet1Name: subnet1Name
    subnet2Prefix: subnet2Prefix
    subnet2Name: subnet2Name
    location: location
  }
}

module dns 'dns.bicep' = {
  name: 'configure-name-resolution'
  scope: resourceGroup('Default')
  params: {
    dnszone: dnszone
    dnsVnetLinkName: dnsVnetLinkName
    vnetId: network.outputs.vnetId
  }
  dependsOn: [
    network
  ]
}

module compute 'compute.bicep' = {
  name: 'vm-deployment'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmNames: vmNames
    vmComputerNames: vmComputerNames
    vmSize: vmSize
    nicNames: nicNames
    pipNames: pipNames
    nsgNames: nsgNames
    pipAllocationMethod: pipAllocationMethod
    pipSku: pipSku
    securityType: securityType
    subnetIds: [
      network.outputs.subnet1Id
      network.outputs.subnet2Id
    ]
    dnsLabelPrefixes: dnsLabelPrefixes
  }
  dependsOn: [
    network
    dns
  ]
}

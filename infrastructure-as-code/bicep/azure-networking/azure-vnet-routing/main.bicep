// Parameters
param location string = resourceGroup().location
param adminUsername string
@secure()
param adminPassword string

// Module for Hub and Spoke Network Configuration
module network 'network.bicep' = {
  name: 'hubSpokeNetwork'
  params: {
    location: location
    hubVnetName: 'vnet-hub-routing-dev-001'
    spokeVnet1Name: 'vnet-a-routing-dev-001'
    spokeVnet2Name: 'vnet-b-routing-dev-001'
    hubVnetAddressPrefix: '10.5.0.0/16'
    spokeVnet1AddressPrefix: '10.6.0.0/16'
    spokeVnet2AddressPrefix: '10.7.0.0/16'
    firewallSubnetPrefix: '10.5.1.0/24'
    vmSubnetPrefix: '10.5.2.0/24'
    spokeVnet1SubnetPrefix: '10.6.1.0/24'
    spokeVnet2SubnetPrefix: '10.7.1.0/24'
  }
}

// Module for Virtual Machine Configuration
module vms 'compute.bicep' = {
  name: 'vmDeployment'
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubVnetName: 'vnet-hub-routing-dev-001'
    hubVmSubnetName: 'vmSubnet'
    spokeVnet1Name: 'vnet-a-routing-dev-001'
    spokeVnet1SubnetName: 'default'
    spokeVnet2Name: 'vnet-b-routing-dev-001'
    spokeVnet2SubnetName: 'default'
    hubVmName: 'hubVm'
    spokeVm1Name: 'spokeVm1'
    spokeVm2Name: 'spokeVm2'
  }
  dependsOn: [
    network
  ]
}

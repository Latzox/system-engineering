param appName string = 'wildflydemo'
param adminUsername string = 'latzo'
param sshKey string
param location string = resourceGroup().location

var cloudInit = base64(loadTextContent('cloudinit.yml'))

module network 'br:latzo.azurecr.io/bicep/modules/network:vnet-snet' = {
  name: 'networkDeployment'
  params: {
    instanceNumber: 001
    environment: 'dev'
    location: location
    addressPrefix: '10.1.0.0/16'
    subnetAddressPrefix: '10.1.0.0/24'
  }
}

module vm 'br:latzo.azurecr.io/bicep/modules/compute:ubuntu-pip' = {
  name: 'vmDeployment'
  params: {
    environment: 'dev'
    instanceNumber: 001
    location: location
    adminPasswordOrKey: sshKey
    adminUsername: adminUsername
    appName: appName
    subnetId: network.outputs.subnetId
    ubuntuOSVersion: 'Ubuntu-2204'
    vmSize: 'Standard_D2s_v3'
    encodedCloudInit: cloudInit
  }
}

output sshCommand string = vm.outputs.sshCommand

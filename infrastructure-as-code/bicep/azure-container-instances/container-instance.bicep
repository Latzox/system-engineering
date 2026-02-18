targetScope = 'subscription'

metadata name = 'Quickstart API Development with ACI'
metadata description = 'This Bicep file deploys an Azure Container Instance running an API'

@description('The name of the Azure Resource Group')
param rgName string = 'rg-dev-api-001'

@description('The location of the deployment')
param location string = 'switzerlandnorth'

@description('The name of the Azure Container Instance')
param aciName string = 'aci-dev-api-001'

@description('The Docker image to deploy')
param dockerImage string = 'latzox.azurecr.io/quickstart-aci-dev-api:latest'

@description('The name of the Azure Container Registry')
param acrName string = 'latzox'

@secure()
param acrPassword string = ''

@description('The network configuration for the container')
param network object = {
  port: 5000
  protocol: 'Tcp'
}

@description('The performance configuration for the container')
param performance object = {
  cpu: 1
  memoryInGB: '2'
}

@description('The name of the container group')
param containerGroupName string = 'acgdevapi001'

@description('The name of the ACI resource group')
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rgName
  location: location
  tags: {
    application: 'quickstart-api-development-with-aci'
    environment: 'dev'
  }
}

@description('The avm module to deploy the container group')
module containerGroup 'br/public:avm/res/container-instance/container-group:0.4.1' = {
  name: guid(rgName, 'containerGroup')
  scope: rg
  params: {
    containers: [
      {
        name: aciName
        properties: {
          image: dockerImage
          ports: [network]
          resources: {
            requests: performance
          }
          environmentVariables: [
            {
              name: 'CLIENT_ID'
              value: aciName
            }
            {
              name: 'CLIENT_SECRET'
              secureValue: 'TestSecret'
            }
          ]
        }
      }
    ]
    name: containerGroupName
    ipAddressPorts: [
      network
    ]
    location: location
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acrName
        password: acrPassword
      }
    ]
    tags: {
      application: 'quickstart-api-development-with-aci'
      environment: 'dev'
    }
  }
}

output containerGroupFqdn string = containerGroup.outputs.iPv4Address

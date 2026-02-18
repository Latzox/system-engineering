param subId string = '0000-000000-000000-0000-0000'

param resourceGroupName string = 'rg-dev-001'

param storageAccountName string = 'sadev001'

module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.0' = {
  scope: subscription(subId)
  name: 'rg-deployment'
  params: {
    name: resourceGroupName
  }
}

module sa 'br/public:avm/res/storage/storage-account:0.15.0' = {
  scope: resourceGroup(resourceGroup)
  name: 'sa-deployment'
  params: {
    name: storageAccountName
  }
}

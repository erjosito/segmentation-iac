@description('String that will be used as a prefix for all resources')
param prefix string = 'app01'
param location string = resourceGroup().location

module app01nsg './nsg-app01.bicep' = {
  name: 'app01-nsg'
  params: {
    nsgName: '${prefix}-nsg'
    location: location
  }
}

module app01vnet './vnet-app01.bicep' = {
  name: '${prefix}-vnet'
  params: {
    vnetName: '${prefix}-vnet'
    location: location
    vnetAddressPrefix: '10.10.10.0/24'
    nsgId: app01nsg.outputs.id
  }
}

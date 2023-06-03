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

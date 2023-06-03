@description('String that will be used as a prefix for all resources')
param prefix string = 'app03dev'
param location string = resourceGroup().location

module app03devnsg './nsg-app03-dev.bicep' = {
  name: 'app03dev-nsg'
  params: {
    nsgName: '${prefix}-nsg'
    location: location
  }
}

@description('String that will be used as a prefix for all resources')
param prefix string = 'app02'
param location string = resourceGroup().location

// The error in the app02nsg happens because there is a file generated at deployment time
module app02nsg './nsg-app02.bicep' = {
  name: 'app02-nsg'
  params: {
    nsgName: '${prefix}-nsg'
    location: location
  }
}

module app02vnet './vnet-app02.bicep' = {
  name: '${prefix}-vnet'
  params: {
    vnetName: '${prefix}-vnet'
    location: location
    vnetAddressPrefix: '10.10.10.0/24'
    // All subnets share the same NSG
    nsgId: app02nsg.outputs.id
  }
}

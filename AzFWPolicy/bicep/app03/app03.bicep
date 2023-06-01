@description('Name of the Azure Firewall Policy')
param policyName string = 'myazurepolicy'
param prefix string = 'app03'

// Location not needed for RCGs, but included any way for consistency and in case IP Groups were required in the future
param location string = resourceGroup().location

module app03RCG './rcg-app03.bicep' = {
  name: 'rcg-app03'
  params: {
    policyName: policyName
    rcgName: 'rcg-${prefix}'
  }
}

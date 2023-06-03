@description('Name of the Azure Firewall Policy')
param policyName string = 'myazurepolicy'

param location string = resourceGroup().location
param prefix string = 'app01'

module app01RCG './rcg-app01.bicep' = {
  name: 'rcg-app01'
  params: {
    policyName: policyName
    rcgName: 'rcg-${prefix}'
  }
  dependsOn: [app01ipgroups]
}

module app01ipgroups './ipgroups-app01.bicep' = {
  name: 'ipgroups-app01'
  params: {
    location: location
    prefix: prefix
  }
}

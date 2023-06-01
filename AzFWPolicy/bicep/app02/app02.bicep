@description('Name of the Azure Firewall Policy')
param policyName string = 'myazurepolicy'
param location string = resourceGroup().location
param prefix string = 'app02'

module app02RCG './rcg-app02.bicep' = {
  name: 'rcg-app02'
  params: {
    policyName: policyName
    rcgName: 'rcg-${prefix}'
  }
  dependsOn: [app02ipgroups]
}

module app02ipgroups './ipgroups-app02.bicep' = {
  name: 'ipgroups-app02'
  params: {
    location: location
    prefix: prefix
  }
}

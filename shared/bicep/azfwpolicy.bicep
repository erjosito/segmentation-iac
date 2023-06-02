@description('Name of the Azure Firewall Policy')
param policyName string

param location string = resourceGroup().location

resource policy 'Microsoft.Network/firewallPolicies@2021-08-01' = {
  location: location
  name: policyName
  properties: {
    dnsSettings: {
      enableProxy: true
    }
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
  }
}

module globalRCG './rcg-global.bicep' = {
  name: 'rcg-global'
  params: {
    policyName: policy.name
    rcgName: 'rcg-global'
  }
}

module app01 '../../app01/bicep/app01.bicep' = {
  name: 'app01'
  params: {
    policyName: policy.name
    prefix: 'app01b'
    location: location
  }
}

module app02 '../../app02/bicep/app02.bicep' = {
  name: 'app02'
  params: {
    policyName: policy.name
    prefix: 'app02b'
    location: location
  }
  // RCGs should be deployed sequentially
  dependsOn: [app01]
}

module app03 '../../app03/bicep/app03.bicep' = {
  name: 'app03'
  params: {
    policyName: policy.name
    prefix: 'app03b'
  }
  // RCGs should be deployed sequentially
  dependsOn: [app02]
}

@description('Name of the Azure Firewall Policy')
param policyName string

param location string = resourceGroup().location
param deployVWAN bool = false

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

module app01 '../../app01/bicep/rcgwrapper-app01.bicep' = {
  name: 'app01'
  params: {
    policyName: policy.name
    prefix: 'app01b'
    location: location
  }
}

module app02 '../../app02/bicep/rcgwrapper-app02.bicep' = {
  name: 'app02'
  params: {
    policyName: policy.name
    prefix: 'app02b'
    location: location
  }
  // RCGs should be deployed sequentially
  dependsOn: [app01]
}

module app03 '../../app03/bicep/rcgwrapper-app03.bicep' = {
  name: 'app03'
  params: {
    policyName: policy.name
    prefix: 'app03b'
  }
  // RCGs should be deployed sequentially
  dependsOn: [app02]
}

// This module exists in a different repo, the syntax highlighting error is expected
module app04 '../../app04/app04/azfw-app04.bicep' = {
  name: 'app04'
  params: {
    policyName: policy.name
    prefix: 'app04b'
  }
  // RCGs should be deployed sequentially
  dependsOn: [app03]
}

// Deploy VWAN with Firewalls associated to the policy
module vwan './vwan/vwan.bicep' = if(deployVWAN) {
  name: 'vwan'
  params: {
    vWANlocation: location
    hub1Location: location
    hub2Location: location
    firewallType: 'Standard'
    FirewallPolicyId: policy.id
  }
  // To deploy VWAN after the policy is finished
  dependsOn: [app04]
}

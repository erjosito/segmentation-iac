@description('Name of the Azure Firewall Policy')
param policyName string = 'myazurepolicy'

@description('Name of the Rule Collection Group')
param rcgName string = 'global-rcg'

resource policyName_rcg 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  name: '${policyName}/${rcgName}'
  properties: {
    priority: 10000
    ruleCollections: [
      {
        action: {
          type: 'allow'
        }
        name: 'Global network rules'
        priority: 10100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Windows-activation'
            destinationAddresses: [
              '20.118.99.224'
              '40.83.235.53'
            ]
            destinationFqdns: []
            destinationIpGroups: []
            destinationPorts: [
              '1688'
            ]
            ipProtocols: [
              'TCP'
            ]
            ruleType: 'NetworkRule'
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
          }
        ]
      }
      {
        action: {
          type: 'allow'
        }
        name: 'Global application rules'
        priority: 10200
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'Ubuntu repositories'
            destinationAddresses: []
            targetFqdns: [
              '*.ubuntu.com'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            ruleType: 'ApplicationRule'
            sourceAddresses: [
              '*'
            ]
            sourceIpGroups: []
            fqdnTags: []
            targetUrls: []
            webCategories: []
          }
        ]
      }
    ]
  }
  dependsOn: []
}

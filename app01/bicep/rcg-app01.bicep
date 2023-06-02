@description('Name of the Azure Firewall Policy')
param policyName string

@description('Name of the Rule Collection Group')
param rcgName string = 'app01-rcg'

resource policyName_rcg 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  name: '${policyName}/${rcgName}'
  properties: {
    priority: 11000
    ruleCollections: [
      {
        action: {
          type: 'allow'
        }
        name: 'app01-network'
        priority: 11100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        rules: [
          {
            name: 'app01-web_to_sql'
            destinationAddresses: []
            destinationFqdns: []
            destinationIpGroups: [
              resourceId('Microsoft.Network/ipGroups', 'app01-sqlservers')
            ]
            destinationPorts: [
              '1433'
            ]
            ipProtocols: [
              'TCP'
            ]
            ruleType: 'NetworkRule'
            sourceAddresses: []
            sourceIpGroups: [
              resourceId('Microsoft.Network/ipGroups', 'app01-appservers')
            ]
          }
          {
            name: 'app01-mgmt'
            destinationAddresses: []
            destinationFqdns: []
            destinationIpGroups: [
              resourceId('Microsoft.Network/ipGroups', 'app01-appservers')
              resourceId('Microsoft.Network/ipGroups', 'app01-sqlservers')
            ]
            destinationPorts: [
              '22'
              '161-162'
            ]
            ipProtocols: [
              'UDP'
              'TCP'
            ]
            ruleType: 'NetworkRule'
            sourceAddresses: [
              '172.16.100.0/24'
            ]
            sourceIpGroups: []
          }
        ]
      }
    ]
  }
  dependsOn: []
}

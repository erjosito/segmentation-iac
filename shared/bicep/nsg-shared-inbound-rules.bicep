@description('NSG name where to attach the rules')
param nsgName string

var dir = 'Inbound'

resource explicitAllowLBInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  name: '${nsgName}/Explicit_Allow_LB'
  properties: {
    access: 'Allow'
    description: 'Allow Azure Load Balancer'
    destinationAddressPrefix: 'VirtualNetwork'
    destinationPortRange: '*'
    direction: dir
    priority: 4094
    protocol: '*'
    sourceAddressPrefix: '168.63.129.16'
    sourcePortRange: '*'
  }
}

resource explicitDenyInbound 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  name: '${nsgName}/Explicit_Deny'
  properties: {
    access: 'Deny'
    description: 'Deny all traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
    direction: dir
    priority: 4095
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}


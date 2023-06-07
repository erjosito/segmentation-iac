@description('Name of the Azure Network Security Group')
param nsgName string = 'app01-prod-nsg'
param location string = resourceGroup().location

resource app01nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
    name: nsgName
    location: location
    properties: {
        securityRules: [
            {
                name: 'anyToWeb-inbound'
                properties: {
                    access: 'Allow'
                    description: 'Allows inbound web access to the web servers'
                    destinationAddressPrefix: '10.10.11.0/28'
                    destinationPortRange: '443'
                    direction: 'inbound'
                    priority: 1010
                    protocol: 'TCP'
                    sourceAddressPrefix: '*'
                    sourcePortRange: '*'
                }
            }
        ]
    }
}

// Deploy shared NSG rules
module sharedInboundRules '../../shared/bicep/nsg-shared-inbound-rules.bicep' = {
  name: 'in-rules-deploy'
  params: { 
    nsgName: app01nsg.name
  }
}

output id string = app01nsg.id

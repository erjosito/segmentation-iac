@description('Name of the Azure Network Security Group')
param nsgName string = 'app01-prod-nsg'
param location string = resourceGroup().location

var securityRules = loadJsonContent('./nsg-rules-app02.json')

resource app03nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
    name: nsgName
    location: location
    properties: securityRules
}

// Deploy shared NSG rules
module sharedInboundRules '../../shared/bicep/nsg-shared-inbound-rules.bicep' = {
  name: 'in-rules-deploy'
  params: { 
    nsgName: app03nsg.name
  }
}

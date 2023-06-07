@description('Name of the Azure Network Security Group')
param nsgName string = 'app01-prod-nsg'
param location string = resourceGroup().location

// VScode will mark the next line as error, because the file is created at build/deploy time
var securityRules = loadJsonContent('./nsg-rules-app02.json')

resource app02nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
    name: nsgName
    location: location
    // VScode will mark the next line as error, because the file is created at build/deploy time
    properties: securityRules
}

// Deploy shared NSG rules
module sharedInboundRules '../../shared/bicep/nsg-shared-inbound-rules.bicep' = {
  name: 'in-rules-deploy'
  params: { 
    nsgName: app02nsg.name
  }
}

output id string = app02nsg.id


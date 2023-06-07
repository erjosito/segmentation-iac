param vnetName string = 'vnet2'
param vnetAddressPrefix string = '10.12.12.0/24'
param nsgId string
param subnets array = [
  {
    name: 'subnet1'
    subnetPrefix: '10.12.12.0/26'
  }
]
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: []
    enableDdosProtection: false
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = [for subnet in subnets: {
  parent: vnet
  name: subnet.name
  properties: {
    addressPrefix: subnet.subnetPrefix
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    networkSecurityGroup: {
      id: nsgId
    }
  } 
}]


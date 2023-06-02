param location string = resourceGroup().location
param prefix string = 'app01'

resource app01_sqlservers 'Microsoft.Network/ipGroups@2021-08-01' = {
  name: '${prefix}-sqlservers'
  location: location
  properties: {
    ipAddresses: [
      '10.10.11.10'
      '10.10.11.11'
    ]
  }
}

resource app01_appservers 'Microsoft.Network/ipGroups@2021-08-01' = {
  name: '${prefix}-appservers'
  location: location
  properties: {
    ipAddresses: [
      '10.10.10.0/23'
      '10.10.11.15'
    ]
  }
}

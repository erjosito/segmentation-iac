param location string = resourceGroup().location
param prefix string = 'app02'

resource app02_sqlservers 'Microsoft.Network/ipGroups@2021-08-01' = {
  name: '${prefix}-sqlservers'
  location: location
  properties: {
    ipAddresses: [
      '10.10.12.10'
      '10.10.12.11'
    ]
  }
}

resource app02_appservers 'Microsoft.Network/ipGroups@2021-08-01' = {
  name: '${prefix}-appservers'
  location: location
  properties: {
    ipAddresses: [
      '10.10.12.13'
      '10.10.12.15'
    ]
  }
}

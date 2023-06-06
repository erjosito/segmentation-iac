param vWANname string = 'vWANtest'
param vWANlocation string = resourceGroup().location 
param deployS2Sgw bool = true
param deployERgw bool = true
param firewallTier string = 'Premium'
param hub1Name string = 'Hub1' 
param hub1Location string
param useZonesForHub1Firewall bool = true
param hub2Name string = 'Hub2'
param hub2Location string
param useZonesForHub2Firewall bool = true
param vWANaddressSpaces array = [
  { hub1: '10.1.0.0/24'
    spoke1: '10.1.1.0/24'
    spoke2: '10.1.2.0/24'
  }
  {
    hub2: '10.2.0.0/24'
    spoke1: '10.2.1.0/24'
    spoke2: '10.2.2.0/24'
  }
]
param FirewallPolicyId string
var LogAnalyticsWorkspaceName = '${vWANname}-LogAnalyticsWS'
var LogAnalyticsWorkspaceSKU = 'pergb2018' // default value is 'pergb2018'
var LogAnalyticsWorkspaceRetentionDays = 30 // default value is 30
var vWANtype = 'Standard' // 'Standard' vWAN is required for Routing Intent and Policy
var hubRoutingPreference = 'ASPath' // "ASPath", "ExpressRoute", "VpnGateway" - default is "ExpressRoute"
var firewallPublicIPnumber = 1 // default value is 1 Public IP per Firewall
var hub1SpokeVnet1name = '${hub1Name}-vnet1' 
var hub1SpokeVnet2name = '${hub1Name}-vnet2' 
var hub2SpokeVnet1name = '${hub2Name}-vnet1' 
var hub2SpokeVnet2name = '${hub2Name}-vnet2' 
var hub1FirewallName = '${vWANname}-${hub1Name}-AzFW' 
var hub2FirewallName = '${vWANname}-${hub2Name}-AzFW' 
var zonesForHub1Firewall = useZonesForHub1Firewall ? ['1','2','3']: []
var zonesForHub2Firewall = useZonesForHub2Firewall ? ['1','2','3']: []
var VpnGatewayScaleUnit = 1
var ErGatewayScaleUnit = 1

resource hub1SpokeVnet1 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: hub1SpokeVnet1name
  location: hub1Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vWANaddressSpaces[0].spoke1 
      ]
    }
    subnets: []
    enableDdosProtection: false
  }
}

resource hub1SpokeVnet2 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: hub1SpokeVnet2name
  location: hub1Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vWANaddressSpaces[0].spoke2 
      ]
    }
    subnets: []
    enableDdosProtection: false
  }
}

resource hub2SpokeVnet1 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: hub2SpokeVnet1name
  location: hub2Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vWANaddressSpaces[1].spoke1  
      ]
    }
    subnets: []
    enableDdosProtection: false
  }
}

resource hub2SpokeVnet2 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: hub2SpokeVnet2name
  location: hub2Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vWANaddressSpaces[1].spoke2
      ]
    }
    subnets: []
    enableDdosProtection: false
  }
}

resource vWAN 'Microsoft.Network/virtualWans@2022-11-01' = {
  name: vWANname
  location: vWANlocation
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    type: vWANtype
  }
}

resource hub1SpokeVnet1Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  parent: hub1SpokeVnet1
  name: '${hub1SpokeVnet1name}-subnet'
  properties: {
    addressPrefix: vWANaddressSpaces[0].spoke1 
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  } 
}

resource hub1SpokeVnet2Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  parent: hub1SpokeVnet2
  name: '${hub1SpokeVnet2name}-subnet'
  properties: {
    addressPrefix: vWANaddressSpaces[0].spoke2
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  } 
}

resource hub2SpokeVnet1Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  parent: hub2SpokeVnet1
  name: '${hub2SpokeVnet1name}-subnet'
  properties: {
    addressPrefix: vWANaddressSpaces[1].spoke1  
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource hub2SpokeVnet2Subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  parent: hub2SpokeVnet2
  name: '${hub2SpokeVnet2name}-subnet'
  properties: {
    addressPrefix: vWANaddressSpaces[1].spoke2
    serviceEndpoints: []
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource hub2Firewall 'Microsoft.Network/azureFirewalls@2022-11-01' = {
  name: hub2FirewallName
  location: hub2Location
  zones: zonesForHub2Firewall
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: firewallTier
    }
    additionalProperties: {}
    virtualHub: {
      id: vWANHub2.id
    }
    hubIPAddresses: {
      publicIPs: {
        count: firewallPublicIPnumber
      }
    }
    firewallPolicy: {
      id: FirewallPolicyId
    }
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [vWANHub2]
}

resource Firewall1DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${hub1FirewallName}-DiagnosticSettings'
  scope: hub2Firewall
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays 
        }
      }
    ]
  }
}

resource hub1Firewall 'Microsoft.Network/azureFirewalls@2022-11-01' = {
  name: hub1FirewallName
  location: hub1Location
  zones: zonesForHub1Firewall
  properties: {
    sku: {
      name: 'AZFW_Hub'
      tier: firewallTier
    }     
    additionalProperties: {
    }
    virtualHub: {
      id: vWANHub1.id
    }
    hubIPAddresses: {      
      publicIPs: {
        count: firewallPublicIPnumber
      }
    }
    firewallPolicy: {
      id: FirewallPolicyId
    }
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [vWANHub1]
}

resource Firewall2DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${hub2FirewallName}-DiagnosticSettings' 
  scope: hub1Firewall
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }
    ]
  }
}

resource vWANHub2 'Microsoft.Network/virtualHubs@2022-11-01' = {
  name: hub2Name
  location: hub2Location
  properties: {
    virtualHubRouteTableV2s: []
    addressPrefix: vWANaddressSpaces[1].hub2 
    virtualRouterAsn: 65515
    routeTable: {
      routes: []
    }
    virtualRouterAutoScaleConfiguration: {
      minCapacity: 2
    }
    virtualWan: {
      id: vWAN.id
    }
    sku: vWANtype
    hubRoutingPreference: hubRoutingPreference

  }
}

resource vWANHub1 'Microsoft.Network/virtualHubs@2022-11-01' = {
  name: hub1Name
  location: hub1Location
  properties: {
    virtualHubRouteTableV2s: []
    addressPrefix: vWANaddressSpaces[0].hub1 
    virtualRouterAsn: 65515
    routeTable: {
      routes: []
    }
    virtualRouterAutoScaleConfiguration: {
      minCapacity: 2
    }
    virtualWan: {
      id: vWAN.id
    }
    sku: vWANtype
    hubRoutingPreference: hubRoutingPreference 
  }
}

resource vWANHub2RoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2022-11-01' = {
  parent: vWANHub2
  name: '${hub2Name}-${hub2Name}_RoutingIntent'
  properties: {
    routingPolicies: [
      {
        name: 'PublicTraffic'
        destinations: [
          'Internet'
        ]
        nextHop: hub2Firewall.id
      }
      {
        name: 'PrivateTraffic'
        destinations: [
          'PrivateTraffic'
        ]
        nextHop: hub2Firewall.id
      }
    ]
  }
}

resource vWANHub1RoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2022-11-01' = {
  parent: vWANHub1
  name: '${hub1Name}-${hub1Name}_RoutingIntent'
  properties: {
    routingPolicies: [
      {
        name: 'PublicTraffic'
        destinations: [
          'Internet'
        ]
        nextHop: hub1Firewall.id
      }
      {
        name: 'PrivateTraffic'
        destinations: [
          'PrivateTraffic'
        ]
       nextHop: hub1Firewall.id
      }
    ]
  }
}

resource hub1VPNs2sGateway 'Microsoft.Network/vpnGateways@2022-11-01' = if (deployS2Sgw == true) {
  name: '${hub1Name}-VPNs2sGateway'
  location: hub1Location
  properties: {
    connections: []
    virtualHub: {
      id: vWANHub1.id
    }
    bgpSettings: {
      asn: 65515
      peerWeight: 0
    }
    vpnGatewayScaleUnit: VpnGatewayScaleUnit
    natRules: []
    enableBgpRouteTranslationForNat: false
    isRoutingPreferenceInternet: false
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [vWANHub1RoutingIntent]
}

resource S2SvpnGw1DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployS2Sgw == true) {
  name: '${hub1Name}-VPNs2sGateway-DiagnosticSettings' 
  scope: hub1VPNs2sGateway
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }
    ]
  }
}

resource hub2VPNs2sGateway 'Microsoft.Network/vpnGateways@2022-11-01' = if (deployS2Sgw == true) {
  name: '${hub2Name}-VPNs2sGateway'
  location: hub2Location
  properties: {
    connections: []
    virtualHub: {
      id: vWANHub2.id
    }
    bgpSettings: {
      asn: 65515
      peerWeight: 0
    }
    vpnGatewayScaleUnit: VpnGatewayScaleUnit 
    natRules: []
    enableBgpRouteTranslationForNat: false
    isRoutingPreferenceInternet: false
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [vWANHub2RoutingIntent]
}

resource S2SvpnGw2DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployS2Sgw == true) {
  name: '${hub2Name}-VPNs2sGateway_DiagnosticSettings'  
  scope: hub2VPNs2sGateway
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }
    ]
  }
}

resource Hub1ErGateway 'Microsoft.Network/expressRouteGateways@2022-11-01' = if (deployERgw == true) {
  name: '${hub1Name}-ErGateway'
  location: hub1Location
  properties: {
    virtualHub: {
      id: vWANHub1.id
    }
    expressRouteConnections: []
    allowNonVirtualWanTraffic: false
    autoScaleConfiguration: {
      bounds: {
        min: ErGatewayScaleUnit
      }
    }
  }
}

resource ErGw1_DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployERgw == true) {
  name: '${hub1Name}-ErGatewayDiagnosticSettings'
  scope: Hub1ErGateway
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [       
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }
    ]
  }
}

resource Hub2ErGateway 'Microsoft.Network/expressRouteGateways@2022-11-01' = if (deployERgw == true){
  name: '${hub2Name}-ErGateway'
  location: hub2Location
  properties: {
    virtualHub: {
      id: vWANHub2.id
    }
    expressRouteConnections: []
    allowNonVirtualWanTraffic: false
    autoScaleConfiguration: {
      bounds: {
        min: ErGatewayScaleUnit
      }
    }
  }
}

resource ErGw2_DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployERgw == true) {
  name: '${hub2Name}-ErGatewayDiagnosticSettings'
  scope: Hub2ErGateway
  properties: {
    workspaceId: LogAnalyticsWorkspace.id
    logs: [     
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true 
          days: LogAnalyticsWorkspaceRetentionDays
        }
      }
    ]
  }
}

resource Hub1VNet1Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-11-01' = {
  parent: vWANHub1
name: '${hub1Name}-to-VNet1-connection'
  properties: {
    remoteVirtualNetwork: {
      id: hub1SpokeVnet1.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [hub1Firewall]
}

resource Hub1VNet2Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-11-01' = {
  parent: vWANHub1
  name: '${hub1Name}-to-VNet2-connection'
  properties: {
    remoteVirtualNetwork: {
      id: hub1SpokeVnet2.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [hub1Firewall]
}

resource Hub2VNet1Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-11-01' = {
  parent: vWANHub2
  name: '${hub2Name}-to-VNet1-connection'
  properties: {
    remoteVirtualNetwork: {
      id: hub2SpokeVnet1.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [hub2Firewall]
}

resource Hub2VNet2Connection 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2022-11-01' = {
  parent: vWANHub2
  name: '${hub2Name}-to-VNet2-connection'
  properties: {
    remoteVirtualNetwork: {
      id: hub2SpokeVnet2.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
  #disable-next-line no-unnecessary-dependson // This is required to avoid conflicts in vWAN RP, some resources must be created in a certain order
  dependsOn: [hub2Firewall]
}

resource LogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: LogAnalyticsWorkspaceName
  location: hub1Location
  properties: {
    sku: {
      name: LogAnalyticsWorkspaceSKU
    }
    retentionInDays: LogAnalyticsWorkspaceRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

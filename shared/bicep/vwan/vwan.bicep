param vWANname string = 'vWANtest'
param vWANlocation string = resourceGroup().location 
param deployS2Sgw bool = false
param deployERgw bool = false
param firewallTier string = 'Premium'
param hub1Name string = 'Hub1' 
param hub1Location string
param useZonesForHub1Firewall bool = true
param vWANaddressSpaces array = [
  { hub1: '10.1.0.0/24'
    spoke1: '10.1.1.0/24'
    spoke2: '10.1.2.0/24'
  }
]
param FirewallPolicyId string
var LogAnalyticsWorkspaceName = '${vWANname}-LogAnalyticsWS'
var LogAnalyticsWorkspaceSKU = 'pergb2018' // default value is 'pergb2018'
var LogAnalyticsWorkspaceRetentionDays = 30 // default value is 30
var vWANtype = 'Standard' // 'Standard' vWAN is required for Routing Intent and Policy
var hubRoutingPreference = 'ASPath' // "ASPath", "ExpressRoute", "VpnGateway" - default is "ExpressRoute"
var firewallPublicIPnumber = 1 // default value is 1 Public IP per Firewall
var hub1FirewallName = '${vWANname}-${hub1Name}-AzFW' 
var zonesForHub1Firewall = useZonesForHub1Firewall ? ['1','2','3']: []
var VpnGatewayScaleUnit = 1
var ErGatewayScaleUnit = 1


resource vWAN 'Microsoft.Network/virtualWans@2022-11-01' = {
  name: vWANname
  location: vWANlocation
  properties: {
    disableVpnEncryption: false
    allowBranchToBranchTraffic: true
    type: vWANtype
  }
}

resource Firewall1DiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${hub1FirewallName}-DiagnosticSettings'
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

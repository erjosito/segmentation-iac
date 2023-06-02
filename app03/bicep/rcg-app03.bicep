@description('Name of the Azure Firewall Policy')
param policyName string

@description('Name of the Rule Collection Group')
param rcgName string = 'app03-rcg'

var rules01 = loadJsonContent('../dev/bicep/rc-app03-01.json')
var rules02 = loadJsonContent('../qa/bicep/rc-app03-02.json')
var rules03 = loadJsonContent('../staging/bicep/rc-app03-03.json')
var rules04 = loadJsonContent('../prod/bicep/rc-app03-04.json')

resource policyName_rcg 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2021-08-01' = {
  name: '${policyName}/${rcgName}'
  properties: {
    priority: 13000
    ruleCollections: [
      rules01
      rules02
      rules03
      rules04
    ]
  }
  dependsOn: []
}

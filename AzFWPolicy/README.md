# Azure Firewall

Azure Firewall has a 3-level hiearchy, with some rules and limits (see [Azure Firewall Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-firewall-limits))that will determine the grouping:

1. Rules: can be application- or network-based
2. Rule collections (RC): one rule collection can only contain network or application rules, but not both
3. Rule collection groups (RCG): maximum 60 per policy, maximum 2MB per Rule Collection Group. They constitute a top level Azure resource, meaning that 

For smaller setups (up to 60 applications), each app can take its own Rule Collection Group. This will enable that each app team gets its own RCG, so that deployments impacting one team will not affect others (since the RCG is an independent resource in Azure).

For larger deployments, a rule collection group would represent a group of applications or Line of Business, and individual applications would get dedicated rule collections.
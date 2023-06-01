# Azure Firewall

Azure Firewall has a 3-level hiearchy, with some rules and limits (see [Azure Firewall Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-firewall-limits))that will determine the grouping:

1. Rules: can be application- or network-based
2. Rule collections (RC): one rule collection can only contain network or application rules, but not both
3. Rule collection groups (RCG): maximum 60 per policy, maximum 2MB per Rule Collection Group. They constitute a top level Azure resource, meaning that 

For smaller setups (up to 60 applications), each app can take its own Rule Collection Group. This will enable that each app team gets its own RCG, so that deployments impacting one team will not affect others (since the RCG is an independent resource in Azure).

For larger deployments, a rule collection group would represent a group of applications or Line of Business, and individual applications would get dedicated rule collections.

## Use separate files

Separate files for each administrative domain in your organization (like application owner groups) will help you to manage access to each item separately and configure different [code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).

Ideally you can separate files at resource boundaries. For example, you can have different files per Rule Collection Group (as in `app01` and `app02` in the example in this repo), and giving access to each Rule Collection Group file to a different application team.

You might need to be more specific. For example, if with the previous scheme you ended up with more than 60 rule collection groups, that wouldn't be supported by Azure Firewall today (check [Azure Limits](https://aka.ms/azurelimit)). You could partition a single Azure resource (the rule collection group in this example) in multiple files, for example using the Azure bicep functions [loadJsonContent](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadjsoncontent) and [loadYamlContent](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadyamlcontent). You can see an example of this setup in this repo, in the [app03 folder](./bicep/app03/rcg-app03.bicep).

## Use Github actions to validate code

Github actions can be used to validate that the different updates to each files don't break your rules. In this repo you can find some examples for validation actions:

- [ipgroups_max](../.github/actions/ipgroups_max/): verifies that the total number of IP Groups defined across the repository doesn't exceed a certain configurable maximum. This example sets the maximum to 80, below the current limit of Azure for 100. This action is using a [shell script](../.github/actions/ipgroups_max/entrypoint.sh).
- [cidr_prefix_length](../.github/actions/cidr_prefix_length/): this Github action loads up JSON with a [Python script](../.github/actions/cidr_prefix_length/entrypoint.py) to verify that the masks of CIDR prefixes used along the different files are not too broad.
- [cidr_prefix_length_bicep](../.github/actions/cidr_prefix_length_bicep/): very similar to the previous one, but in the case of bicep there is no JSON to load. Hence [pycep-parser](https://pypi.org/project/pycep-parser/) needs to be leveraged to transform bicep into JSON before analyzing it. See the [Python script](../.github/actions/cidr_prefix_length_bicep/entrypoint.py) for more details.

It is important that you define the file path and extensions that will trigger each check: you don't want to run ARM validation on bicep files or vice versa. In the workflows for [ARM validation](../.github/workflows/deploy_azfw_arm.yml) and [bicep validation](../.github/workflows/deploy_azfw_bicep.yml) you find examples of this, for example to run the validation only when files in the ARM directory are changed:

```
on:
  push:
    branches: [master]
    paths:
      - 'AzFWPolicy/ARM/**.json'
```

## Manage concurrency

Azure Firewall doesn't support concurrent operations, so you need to configure your workflows to never run concurrently. Github workflows offer the [concurrency](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) attribute for jobs to manage this, you can check how the [ARM workflow](../.github/workflows/deploy_azfw_arm.yml) and [bicep workflow](../.github/workflows/deploy_azfw_arm.yml) for Azure Firewall are configured to belong to the same concurrency group.

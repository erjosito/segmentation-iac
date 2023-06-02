# Azure Network Segmentation Infrastructure as Code

This repo contains examples of different IaC approaches for network segmentation in Azure. In Azure there are two main technologies to separate workloads from each other:

- Azure Firewall
  - Network rules
  - Application rules
- Network Security Groups
  - IP-based
  - Application Security Groups (a sort of label assigned to the NIC's IP configuration)

# Azure Firewall

We will start the discussion with examples to deploy Azure Firewall, a resource that is centralized in a shared subscription.

Azure Firewall has a 3-level hierarchy, with some rules and limits (see [Azure Firewall Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-firewall-limits))that will determine the grouping:

1. Rules: can be application- or network-based
2. Rule collections (RC): one rule collection can only contain network or application rules, but not both
3. Rule collection groups (RCG): maximum 60 per policy, maximum 2MB per Rule Collection Group. They constitute a top level Azure resource, meaning that 

For smaller setups (up to 60 applications), each app can take its own Rule Collection Group. This will enable that each app team gets its own RCG, so that deployments impacting one team will not affect others (since the RCG is an independent resource in Azure).

For larger deployments, a rule collection group would represent a group of applications or Line of Business, and individual applications would get dedicated rule collections.

## Use protected branches

You should [protect](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches) the main/master branch, so that users always need to go through the Pull Request process, and not push straight into the branches. Different tests and checks will be performed in the PR, and a manual approval should be required before merging the PR.

![branch protection](./images/branch_protection.png)

## Use separate files

Separate files for each administrative domain in your organization (like application owner groups) will help you to manage access to each item separately and configure different [code owners](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners).

Ideally you can separate files at resource boundaries. For example, you can have different files per Rule Collection Group (as in `app01` and `app02` in the example in this repo), and giving access to each Rule Collection Group file to a different application team.

You might need to be more specific. For example, if with the previous scheme you ended up with more than 60 rule collection groups, that wouldn't be supported by Azure Firewall today (check [Azure Limits](https://aka.ms/azurelimit)). You could partition a single Azure resource (the rule collection group in this example) in multiple files, for example using the Azure bicep functions [loadJsonContent](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadjsoncontent) and [loadYamlContent](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-files#loadyamlcontent). You can see an example of this setup in this repo, in the [app03 folder](app03/bicep/rcg-app03.bicep)

An alternative approach can be seen in the [app03 ARM directory](./app03/ARM), where the script [merge_rcg.py](scripts/merge_rcg.py) consolidates the different files into a single one.

## Single vs multiple templates

Two different approaches are presented in this repo:

1. Option 1 (recommended): **single template**. This the approach followed in the [bicep directory](shared/bicep/). Whenever anything changes in any of the files, the whole lot is deployed again. Since the templates are idempotent, applying everything shouldn't trigger any change on resources that do not have changes. One benefit of this approach is that the dependencies are taken care of inside of the template, for example making sure that IP groups are created before the rule collection groups, so the [workflow](.github/workflows/check_bicep_code.yml) is kept relatively simple.
1. Option 2: **multiple templates**. This is the approach followed in the [ARM directory](shared/ARM/). While this approach gives a more granular control on the templates that are deployed, it moves the logic from inside the template to the [Github workflow](.github/workflows/deploy_azfw_arm.yml). ARM doesn't have such an advanced file management mechanism like bicep or Terraform, so if you are going with ARM this might be they only possible approach that allows to keep files separated.

## Use Github actions to validate code

Github actions can be used to validate that the different updates to each files don't break your rules. In this repo you can find some examples for validation actions:

- [ipgroups_max](.github/actions/ipgroups_max/): verifies that the total number of IP Groups defined across the repository doesn't exceed a certain configurable maximum. This example sets the maximum to 80, below the current limit of Azure for 100. This action is using a [shell script](.github/actions/ipgroups_max/entrypoint.sh).
- [cidr_prefix_length](.github/actions/cidr_prefix_length/): this Github action loads up JSON with a [Python script](.github/actions/cidr_prefix_length/entrypoint.py) to verify that the masks of CIDR prefixes used along the different files are not too broad.
- [cidr_prefix_length_bicep](.github/actions/cidr_prefix_length_bicep/): very similar to the previous one, but in the case of bicep there is no JSON to load. Hence [pycep-parser](https://pypi.org/project/pycep-parser/) needs to be leveraged to transform bicep into JSON before analyzing it. See the [Python script](.github/actions/cidr_prefix_length_bicep/entrypoint.py) for more details.

It is important that you define the file path and extensions that will trigger each check: you don't want to run ARM validation on bicep files or vice versa. In the workflows for [ARM validation](.github/workflows/deploy_azfw_arm.yml) and [bicep validation](.github/workflows/deploy_azfw_bicep.yml) you find examples of this, for example to run the validation only when files in the ARM directory are changed:

```
on:
  pull_request:
    branches: [master]
    paths:
      - '**/ARM/*.json'
```

## Continuous deployment or nightly deployments

Once a Pull Request is merged, you can decide to deploy straight into the target environment, or whether to wait and deploy all changes at a fixed time, such as once a day. If you go for the continuous deployment option, your worflow should match both the main/master branch as well as the relevant files:

```
on:
  push:
    branches: [master]
    paths:
      - '**/ARM/*.json'
```

If this filtering is not enough, you can use additional in-job filters to control actions, for example with the [dorny/paths-filter](https://github.com/dorny/paths-filter) Github action, as shown in the [ARM workflow](.github/workflows/deploy_azfw_arm.yml).

If going for scheduled deployments, you can leverage the [on.schedule functionality](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#onschedule) in your Github actions. If you would like to deploy **only** if there were some commits in the period, you can use a variable containing the number of commits (24 hours in this example) to determine whether to run the deployment or not:

```
- name: Get number of commits
  run: echo "NEW_COMMIT_COUNT=$(git log --oneline --since '24 hours ago' | wc -l)" >> $GITHUB_ENV
```

## Manage concurrency

Azure Firewall doesn't support concurrent operations, so you need to configure your workflows to never run concurrently. Github workflows offer the [concurrency](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions#concurrency) attribute for jobs to manage this, you can check how the [ARM workflow](.github/workflows/deploy_azfw_arm.yml) and [bicep workflow](.github/workflows/deploy_azfw_arm.yml) for Azure Firewall are configured to belong to the same concurrency group.

## Import code from other repositories

The same concept followed so far can be used as well in multi-repo approaches, where the infra code for other apps is located in remote repositories. In this sample I just checkout the whole remote repository in the workflow. For example, for an `app04` stored in a remote repo `segmentation-iac-app04`, the [bicep workflow](.github/workflows/deploy_azfw_bicep.yml) checks out both the local and the remote repos:

```
    # Checkout local repo
    - name: Checkout local repo
      uses: actions/checkout@main
    # Checkout remote repo for app04 (the path is important, the bicep template expects to find it there)
    - name: Checkout app04 repo
      uses: actions/checkout@v2
      with:
        repository: erjosito/segmentation-iac-app04
        ref: master
        path: './app04'
```

The [bicep template](./shared/bicep/azfwpolicy.bicep) is configured to look for the module `azfw-app04.bicep` in the `app04` folder, where the remote repo will be cloned.

# Network Security Groups

Network Security Groups (NSGs) are an interesting exercise, since opposite to Azure Firewall policies, they are completely distributed. Looking at our application `app04` with a separate repository ([segmentation-iac-app04](https://github.com/erjosito/segmentation-iac-app04)), this application will be deployed in a different subscription, with a different Virtual Network, and of course different NSGs.

The Azure credentials, including the subscription ID and resource group for `app04` are stored in the secrets of that repo. NSGs should be deployed in the same subscription as the VNet, and hence it is only logical that the deployment workflow runs in the `app04`'s repo (the repo with the shared resources shouldn't need the credentials to the workload's subscription). And yet, the shared repo might contain some required information.

In this example, the shared repo contains some [common NSG rules](./shared/bicep/nsg-shared-inbound-rules.bicep) that are to be inserted in every NSG for all workloads. Consequently, the [workflow in segmentation-iac-app04](https://github.com/erjosito/segmentation-iac-app04/blob/master/.github/workflows/deploy_prod_nsg_bicep.yml) checks out the shared repo as well, and the [NSG bicep template](https://github.com/erjosito/segmentation-iac-app04/blob/master/app04/prod/nsg-app04-prod.bicep) contains a module to be found in the folder where the shared repo is cloned.

After running the template, you can see that the NSG is created with the rules contained in the local repo, and the shared rules from the shared one:

![app04 NSG](./images/app04_nsg.png)
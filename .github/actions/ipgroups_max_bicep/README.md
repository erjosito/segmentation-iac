# Maximum number of IP Groups check

This action verifies that the templates in the repo do not contain too many IP groups.

## Inputs

## `file_prefix`

**Optional** File prefix for the ARM templates to be analyzed. Default `"ipgroups"`.

## `file_extension`

**Optional** File extension for the ARM templates to be analyzed. Default `"bicep"`.

## `max_ipgroups`

**Optional** Maximum number of IP groups allowed. Default `"80"`.

## Example usage

```
uses: ./.github/actions/ipgroups_max
with:
  file_prefix: 'ipgroups'
  file_extension: 'bicep'
  max_ip_groups: '80'
```

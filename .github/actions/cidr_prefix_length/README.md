# Maximum number of IP Groups check

This action verifies that the templates in the repo do not contain too many IP groups.

## Inputs

## `file_prefix`

**Optional** File prefixes (space-separated) for the ARM templates to be analyzed. Default `"ipgroups rcg"`.

## `file_extension`

**Optional** File extension for the ARM templates to be analyzed. Default `"json"`.

## `min_cidr_length`

**Optional** Minimum CIDR prefix length allowed. Default `"24"`.

## Example usage

```
uses: ./.github/actions/cidr_prefix_length
with:
  file_prefix: 'ipgroups rcg'
  file_extension: 'json'
  min_cidr_length: '24'
```
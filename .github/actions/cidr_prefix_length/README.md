# Maximum number of IP Groups check

This action verifies that the templates in the repo do not contain too many IP groups.

## Inputs

## `file_prefixes`

**Optional** File prefixes (space-separated) for the ARM templates to be analyzed. Default `"ipgroups rcg"`.

## `file_extension`

**Optional** File extension for the ARM templates to be analyzed. Default `"json"`.

## `min_cidr_length`

**Optional** Minimum CIDR prefix length allowed. Default `"24"`.

## `base_dir`

**Optional** Directory where to look for files. Default `"./"`.

## Example usage

```
uses: ./.github/actions/cidr_prefix_length
with:
  file_prefixes: 'ipgroups rcg'
  file_extension: 'json'
  min_cidr_length: '24'
  base_dir: './'
```

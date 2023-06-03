# Maximum number of IP Groups check

This action verifies that the templates in the repo do not contain too many IP groups.

## Inputs

## `file_prefixes`

**Optional** File prefixes (space-separated) for the ARM templates to be analyzed. Default `"ipgroups rcg"`.

## `file_extension`

**Optional** File extension for the ARM templates to be analyzed. Default `"bicep"`.

## `min_prio`

**Optional** Minimum priority allowed for a rule collection (group). Default `"10000"`.

## `max_prio`

**Optional** Maximum priority allowed for a rule collection (group). Default `"40000"`.

## `base_dir`

**Optional** Directory where to look for files. Default `"./"`.

## Example usage

```
uses: ./.github/actions/cidr_prefix_length
with:
  file_prefix: 'ipgroups rcg'
  file_extension: 'json'
  min_prio: '10000'
  max_prio: '40000'
  base_dir: './'
```

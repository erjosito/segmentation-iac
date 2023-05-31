import sys
import glob
import json
import argparse

# Parse arguments with argparse
parser = argparse.ArgumentParser(description='Merge Azure Firewall Policy files')
parser.add_argument('--directory', type=str, help='Folder where the files to process are located')
parser.add_argument('--output-file', type=str, help='File where the merged file will be written')
parser.add_argument('--verbose', action='store_true', default=False, help='Verbose output')
args = parser.parse_args()

# Default output file to merged.json in the input directory
if not args.output_file:
    args.output_file = args.directory + '/merged.json'

# Global variables
rcg_file_prefix='rcg-'
rc_file_prefix='rc-'

# Read file to JSON
def read_file(file):
    f = open(file, 'r')
    try:
        data = json.load(f)
        return data
    except:
        print("ERROR: Unable to parse JSON file '{0}'".format(file))
        return None

# List with all files in the directory
rcg_files = glob.glob(args.directory + '/' + rcg_file_prefix + '*.json', recursive=True)
rc_files = glob.glob(args.directory + '/' + rc_file_prefix + '*.json', recursive=True)

# Error out if not exactly one file found
if args.verbose:
    print("DEBUG: Found {0} files with prefix '{1}'".format(len(rcg_files), rcg_file_prefix))
if len(rcg_files) == 0:
    print("ERROR: No files found with prefix '{0}'".format(rcg_file_prefix))
    exit(1)
elif len(rcg_files) > 1:
    print("ERROR: more than one file found with prefix '{0}'".format(rcg_file_prefix))

# Verify that RCG file contains an RCG
rcg = read_file(rcg_files[0])
if rcg['resources'][0]['type'].lower() != 'Microsoft.Network/firewallPolicies/ruleCollectionGroups'.lower():
    print("ERROR: File '{0}' does not contain a rule collection group".format(rcg_files[0]))
    exit(1)
else:
    if args.verbose:
        print("DEBUG: Found RCG '{0}'".format(rcg['resources'][0]['name']))

# Append the RCs to the RCG
if args.verbose:
    print("DEBUG: Merging {0} files".format(len(rc_files)))
for rc_file in rc_files:
    rc = read_file(rc_file)
    if rc is not None:
        rcg['resources'][0]['properties']['ruleCollections'].append(rc)

# Write the merged RCG to a file
with open(args.output_file, 'w') as outfile:
    json.dump(rcg, outfile, indent=4)


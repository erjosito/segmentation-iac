import sys
import glob
import json
import argparse
import os

# Parse arguments with argparse
parser = argparse.ArgumentParser(description='Merge Azure Firewall Policy files')
parser.add_argument('--rcg-file', type=str, help='File path to the ARM template with the RCG')
parser.add_argument('--rc-directories', type=str, help='Folders (blank separated) where the files to process are located')
parser.add_argument('--output-file', type=str, help='File where the merged file will be written')
parser.add_argument('--verbose', action='store_true', default=False, help='Verbose output')
args = parser.parse_args()

# Exit if no rcg file was provided
if not args.rcg_file:
    print("ERROR: No RCG file provided")
    exit(1)
# Default RC directories to current directory
if not args.rc_directories:
    rc_directory_list = ['.']
else:
    rc_directory_list = args.rc_directories.split()
# Default output file to merged.json in the directory of the rcg template
if not args.output_file:
    args.output_file = os.path.join(os.path.dirname(args.rcg_file), 'merged.json')

# Global variables
rcg_file_prefix='rcg-'
rc_file_prefix='rc-'

# Function to read a text file into JSON
def read_file(file):
    f = open(file, 'r')
    try:
        data = json.load(f)
        return data
    except:
        print("ERROR: Unable to parse RCG JSON file '{0}'".format(file))
        return None

# Load the RCG file and verify that RCG file contains an RCG
rcg = read_file(args.rcg_file)
if rcg['resources'][0]['type'].lower() != 'Microsoft.Network/firewallPolicies/ruleCollectionGroups'.lower():
    print("ERROR: RCG file '{0}' does not contain a rule collection group".format(args.rcg_file))
    exit(1)
else:
    if args.verbose:
        print("DEBUG: Found RCG '{0}'".format(rcg['resources'][0]['name']))

# Load the RC files
for directory in rc_directory_list:
    # Find the RC files in the directory (typically only one)
    rc_files = glob.glob(directory + '/' + rc_file_prefix + '*.json', recursive=True)
    # Append the RCs to the RCG
    if args.verbose:
        print("DEBUG: Merging {0} files".format(len(rc_files)))
    for rc_file in rc_files:
        rc = read_file(rc_file)
        if rc is not None:
            rcg['resources'][0]['properties']['ruleCollections'].append(rc)
        else:
            print("ERROR: Unable to parse RC JSON file '{0}'".format(rc_file))

# Write the merged RCG to a file
with open(args.output_file, 'w') as outfile:
    json.dump(rcg, outfile, indent=4)

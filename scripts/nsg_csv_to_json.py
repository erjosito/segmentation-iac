import sys
import glob
import json
import argparse
import os

# Parse arguments with argparse
parser = argparse.ArgumentParser(description='Convert NSG files in CSV format to ARM-compatible JSON')
parser.add_argument('--csv-file', type=str, help='File path to the CSV file with the rules')
parser.add_argument('--output-file', type=str, help='File where the JSON file will be written (default: securityRules.json)')
parser.add_argument('--ignore-first-line', action='store_true', default=True, help='Ignore first line of CSV file (default: True)')
parser.add_argument('--verbose', action='store_true', default=False, help='Verbose output')
args = parser.parse_args()

# Exit if no rcg file was provided
if not args.csv_file:
    print("ERROR: No CSV file was provided")
    exit(1)
# Default output file to securityRules.json in the directory of the CSV files
if not args.output_file:
    args.output_file = os.path.join(os.path.dirname(args.csv_file), 'securityRules.json')

# Open input file and split it to an array of lines
try:
    if args.verbose:
        print("DEBUG: Reading CSV file '{0}'".format(args.csv_file))
    with open(args.csv_file) as csv_file:
        nsg_csv = csv_file.readlines()
    if args.verbose:
        print("DEBUG: Read {0} lines from CSV file".format(len(nsg_csv)))
    if args.ignore_first_line:
        if args.verbose:
            print("DEBUG: Ignoring first line of CSV file")
        nsg_csv = nsg_csv[1:]
except:
    print("ERROR: Unable to parse CSV JSON file '{0}'".format(args.csv_file))
    sys.exit(1)

# Create the JSON object
nsg_json = { "securityRules": [] }
for line in nsg_csv:
    line = line.strip()
    line = line.split(',')
    if len(line) == 10:
        new_security_rule = {
            "name": line[0].strip() + line[2].strip(),  # Direction appended to name
            "properties": {
                "description": line[1].strip(),
                "direction": line[2].strip(),
                "access": line[3].strip(),
                "priority": line[4].strip(),
                "protocol": line[5].strip(),
                "sourceAddressPrefix": line[6].strip(),
                "sourcePortRange": line[7].strip(),
                "destinationAddressPrefix": line[8].strip(),
                "destinationPortRange": line[9].strip()
            }
        }
        if args.verbose:
            print("DEBUG: Adding security rule '{0}'".format(new_security_rule['name']))
        nsg_json["securityRules"].append(new_security_rule)
    else:
        print("ERROR: Invalid line '{0}'".format(line))

# Write the JSON object to the output file
if args.verbose:
    print("DEBUG: Writing JSON to '{0}'".format(args.output_file))
with open(args.output_file, 'w') as outfile:
    json.dump(nsg_json, outfile, indent=4)
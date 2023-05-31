import sys
import glob
import json

# Global variables
base_dir = "./AzFWPolicy/ARM"
lowest_cidr_found = 32

# Read parameters
try:
    file_prefixes = sys.argv[1]
except:
    file_prefixes = "ipgroups rcg"
try:
    file_extension = sys.argv[2]
except:
    file_extension = "json"
try:
    min_cidr_length = int(sys.argv[3])
except:
    min_cidr_length = 24
print("DEBUG: Running with file_prefixes='{0}', file_extension='{1}', min_cidr_length={2}".format(file_prefixes, file_extension, min_cidr_length))

# Process list of CIDRs
def process_cidr_list(cidr_list):
    global lowest_cidr_found
    print("DEBUG: Processing CIDR list with {0} items: {1}".format(len(cidr_list), str(cidr_list)))
    for cidr in cidr_list:
        if '/' in cidr:
            cidr_prefix_length = int(cidr.split('/')[1])
            if cidr_prefix_length < lowest_cidr_found:
                lowest_cidr_found = cidr_prefix_length
            if cidr_prefix_length < min_cidr_length:
                print("WARNING: CIDR '{0}' in file '{1}' is shorter than {2}".format(cidr, file, min_cidr_length))

# Read files
file_prefix_list=file_prefixes.split(' ')
for file_prefix in file_prefix_list:
    print("DEBUG: Processing files with prefix '{0}' in '{1}'".format(file_prefix, base_dir))
    files = glob.glob(base_dir + '/**/' + file_prefix + '*.' + file_extension, recursive=True)
    for file in files:
        print("DEBUG: Processing file '{0}'".format(file))
        f = open(file, 'r')
        try:
            data = json.load(f)
            if 'resources' in data:
                for resource in data['resources']:
                    print("DEBUG: Found resource {0} of type {2} in file '{1}'".format(resource['name'], file, resource['type']))
                    if resource['type'].lower() == 'Microsoft.Network/ipGroups'.lower():
                        process_cidr_list(resource['properties']['ipAddresses'])
                    elif resource['type'].lower() == 'Microsoft.Network/firewallPolicies/ruleCollectionGroups'.lower():
                        rcs = resource['properties']['ruleCollections']
                        for rc in rcs:
                            print("DEBUG: Found rule collection '{0}' in file '{1}'".format(rc['name'], file))
                            if 'rules' in rc:
                                for rule in rc['rules']:
                                    if 'destinationAddresses' in rule:
                                        process_cidr_list(rule['destinationAddresses'])
                                    if 'sourceAddresses' in rule:
                                        process_cidr_list(rule['sourceAddresses'])
                            else:
                                print("WARNING: No rules found in rule collection '{0}' in file '{1}'".format(rc['name'], file))
        except Exception as e:
            print("ERROR: Unable to parse JSON file '{0}': {1}".format(file, str(e)))
            continue

# Exit
if lowest_cidr_found < min_cidr_length:
    print("ERROR: Lowest CIDR found was {0}, which is shorter than {1}".format(lowest_cidr_found, min_cidr_length))
    exit(1)
else:
    print("INFO: Lowest CIDR found was {0}, compatible with the minimum defined of {1}".format(lowest_cidr_found, min_cidr_length))
    exit(0)


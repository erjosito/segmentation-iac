import sys
import glob
import json
from pathlib import Path
from pycep import BicepParser

# Global variables
min_prio_found = None
max_prio_found = None
prios_found = []

# Read parameters
try:
    file_prefixes = sys.argv[1]
except:
    file_prefixes = "rcg"
try:
    file_extension = sys.argv[2]
except:
    file_extension = "json"
try:
    min_prio = int(sys.argv[3])
except:
    min_prio = 10000
try:
    max_prio = int(sys.argv[4])
except:
    max_prio = 40000
try:
    base_dir = int(sys.argv[5])
except:
    base_dir = "./"

print("DEBUG: Running with file_prefixes='{0}', file_extension='{1}', min_prio={2}, max_prio={3}, base_dir='{4}'".format(file_prefixes, file_extension, min_prio, max_prio, base_dir))

# Read files
file_prefix_list=file_prefixes.split(' ')
for file_prefix in file_prefix_list:
    print("DEBUG: Processing files with prefix '{0}' in '{1}'".format(file_prefix, base_dir))
    files = glob.glob(base_dir + '/**/' + file_prefix + '*.' + file_extension, recursive=True)
    for file in files:
        print("DEBUG: Processing file '{0}'".format(file))
        try:
            data = BicepParser().parse(file_path=Path(file))
            if 'resources' in data:
                for resource_key in data['resources']:
                    print("DEBUG: Found resource {0} of type {2} in file '{1}'".format(resource_key, file, data['resources'][resource_key]['type']))
                    resource = data['resources'][resource_key]
                    if resource['type'].lower() == 'Microsoft.Network/firewallPolicies/ruleCollectionGroups'.lower():
                        if 'config' in resource and 'properties' in resource['config'] and 'priority' in resource['config']['properties']:
                            rcg_prio = int(resource['config']['properties']['priority'])
                            # Update min/max prio found
                            if min_prio_found is None or rcg_prio < min_prio_found:
                                min_prio_found = rcg_prio
                            if max_prio_found is None or rcg_prio > max_prio_found:
                                max_prio_found = rcg_prio
                            # Show info messages for this RCG
                            if rcg_prio < min_prio:
                                print("ERROR: Found rule collection group '{0}' with priority {1}, which is lower than the minimum defined of {2}".format(resource_key, rcg_prio, min_prio))
                            if rcg_prio > max_prio:
                                print("ERROR: Found rule collection group '{0}' with priority {1}, which is higher than the maximum defined of {2}".format(resource_key, rcg_prio, max_prio))
                            # Update prio found array and check for duplicates
                            if rcg_prio in prios_found:
                                print("ERROR: Found rule collection group '{0}' with priority {1}, which is already used".format(resource_key, rcg_prio))
                            prios_found.append(rcg_prio)
                        else:
                            print("WARNING: No priority found in resource '{0}' in file '{1}'".format(resource_key, file))
                        rcs = resource['config']['properties']['ruleCollections']
                        print ("DEBUG: Found {0} rule collections in file '{1}'".format(len(rcs), file))
                        for rc in rcs:
                            if 'name' in rc:
                                print("DEBUG: Found rule collection '{0}' in file '{1}'".format(rc['name'], file))
                                if 'priority' in rc:
                                    rc_prio = int(rc['priority'])
                                    # Update min/max prio found
                                    if min_prio_found is None or rc_prio < min_prio_found:
                                        min_prio_found = rc_prio
                                    if max_prio_found is None or rc_prio > max_prio_found:
                                        max_prio_found = rc_prio
                                    # Show info messages for this RC
                                    if rc_prio < min_prio:
                                        print("ERROR: Found rule collection '{0}' with priority {1}, which is lower than the minimum defined of {2}".format(rc['name'], rc_prio, min_prio))
                                    if rc_prio > max_prio:
                                        print("ERROR: Found rule collection '{0}' with priority {1}, which is higher than the maximum defined of {2}".format(rc['name'], rc_prio, max_prio))
                                    # Update prio found array and check for duplicates
                                    if rc_prio in prios_found:
                                        print("ERROR: Found rule collection group '{0}' with priority {1}, which is already used".format(resource_key, rcg_prio))
                                    prios_found.append(rc_prio)
                                else:
                                    print("WARNING: No priority found in rule collection '{0}' in file '{1}'".format(rc['name'], file))
                            else:
                                print("WARNING: No name found in rule collection '{1}' in file '{0}'".format(file, str(rc)))
        except Exception as e:
            print("ERROR: Unable to parse bicep file '{0}': {1}".format(file, str(e)))
            continue

# Exit
if min_prio_found < min_prio:
    print("ERROR: Lowest prio found was {0}, which is shorter than {1}".format(min_prio_found, min_prio))
    exit(1)
elif max_prio_found > max_prio:
    print("ERROR: Highest prio found was {0}, which is larger than {1}".format(max_prio_found, max_prio))
    exit(1)
elif len(prios_found) != len(set(prios_found)):
    print("ERROR: Duplicate priorities found across rule collections and rule collection groups")
    exit(1)
else:
    print("INFO: Priorities found between {0} and {1}, in the allowed range ({2}-{3})".format(min_prio_found, max_prio_found, min_prio, max_prio))
    print("INFO: No duplicate priorities found across rule collections and rule collection groups")
    exit(0)


import sys
import glob
import json

# Global variables
base_dir = "./AzFWPolicy/ARM"

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

# Read files
file_prefix_list=file_prefixes.split(' ')
for file_prefix in file_prefix_list:
    print("DEBUG: Processing files with prefix '{0}'".format(file_prefix))
    files = glob.glob(base_dir + '/' + file_prefix + '*.' + file_extension, recursive=True)
    for file in files:
        print("DEBUG: Processing file '{0}'".format(file))
        f = open(file, 'r')
        try:
            data = json.load(f)
            for resource in data['resources']:
                print("DEBUG: Found resource {0} in file '{1}'".format(resource['name'], file))
        except:
            print("ERROR: Unable to parse JSON file '{0}'".format(file))
            continue



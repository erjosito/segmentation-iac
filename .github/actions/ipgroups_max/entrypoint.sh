#!/bin/sh -l

# Initialization
file_prefix="$1"
file_extension="$2"
max_ipgroup_no="$3"
ipgroup_no=0

# Info message
echo "DEBUG: Running with file_prefix=$file_prefix, file_extension=$file_extension."

# Find all files with the given prefix and extension
file_list=$(find . -type f -name "$file_prefix*$file_extension" -print)

# Go file by file and count the number of IP groups
for file in $file_list; do
    this_ipgroup_no=$(cat $file | jq -r '.resources[].name' | wc -l)
    echo "DEBUG: Found $this_ipgroup_no IP groups in $file."
    ipgroup_no=$((ipgroup_no + this_ipgroup_no))
done

# Output
echo "number_of_ipgroups=$ipgroup_no" >> $GITHUB_OUTPUT

# Finish
if [ "$ipgroup_no" -gt "$max_ipgroup_no" ]; then
    echo "ERROR: Found $ipgroup_no IP groups, which is more than the maximum of $max_ipgroup_no."
    exit 1
else
    echo "INFO: Found $ipgroup_no IP groups, which is not more than the maximum of $max_ipgroup_no."
    exit 0
fi
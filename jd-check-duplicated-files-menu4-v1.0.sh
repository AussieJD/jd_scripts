#!/bin/bash
#
# Use find to locate folders in the local directory
echo "1"
folders=$(find . -type d -not -name ".")

# Loop through each folder found
echo "2"
IFS=$'\n' # Set Internal Field Separator to newline to handle spaces in folder names
for folder in $folders; do
    # Use du -h to display the disk usage of each folder
	echo "-- folder = $folder"
    du -h "${folder}"
done

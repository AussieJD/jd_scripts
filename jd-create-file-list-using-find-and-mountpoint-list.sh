#!/bin/bash
#
# create a file list / index based on find, using a list file containing "mountpoints / folders" to search
#

#MYPWD=`pwd`
MYPWD="/Users/jon/scripts/onedrive_scripts_master"
FOLDER_LIST="jd-create-file-list-folder-list.txt"
MYDATE=`date '+%Y-%m-%d-%H_%M'`
OUTPUTFILE1="jd-find-master-dot-out-$MYDATE.out"

[[ -f $OUTPUTFILE1 ]] && rm "$OUTPUTFILE1"

while IFS= read -r line; do
	# Process the line here
	echo "Line: $line"
	#ls "${line}"
	find "${line}" -type f >> $OUTPUTFILE1 2>/dev/null
	echo "****" >> $OUTPUTFILE1

done < "$MYPWD/$FOLDER_LIST"

# The End!

#!/bin/bash


# create a lot of small files in a lot of folders to test parallel rsync scripts

# variables

NUM_FOLDERS=20			# number of folders
NUM_FILES=50			# number of files in each folder
FILE_SIZE=20			# size of each file in MB (intention is to use mkfile)

FILE_NAME_STUB="test_file_"
FOLDER_NAME_STUB="test_folder_"

COUNT1=1

## Main 

# clean up folders (recursively) - deletes all folders and their files
for folder in $(ls -d */);do echo "... removing $folder";rm -rf ${folder};done

# once in desired folder, create files
for SEQ1 in $(seq -f "%03g" 1 $NUM_FILES)
 do
	echo $SEQ1
done

# The End!

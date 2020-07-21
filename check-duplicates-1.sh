#!/bin/bash
#
# Use spotlight (mdfind) to check if a files in a folder exist somewhere else
#
COUNT=1
#
DIR="$1"
 
# failsafe - fall back to current directory
[ "$DIR" == "" ] && DIR="."
 
# save and change IFS 
OLDIFS=$IFS
IFS=$'\n'
 
# read all file name into an array
#fileArray=($(find $DIR -type f))
fileArray=($(ls $DIR ))
 
# restore it 
IFS=$OLDIFS
 
# get length of an array
tLen=${#fileArray[@]}
 
# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
	COUNT=1
  	echo "${fileArray[$i]}"
	for j in `mdfind -name ""${fileArray[$i]}""`
	 do
		echo "$COUNT. $j"
		COUNT=$(( $COUNT + 1 ))
	done
done


# The End!

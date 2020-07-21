#!/bin/bash
#
# Usage:	extract the device ID and size in 512-byte blocks from
#		an output of symdevlist -v
# 	variables:
#		lines containing = Device Symmetrix Name   	
#		lines containing = 512-byte Blocks
#	special requirement:
#		if lines starting with 512-byte are repeated, only output the first occurance
#
# Created:	2-Dec-2011		jon driscoll	jonathon.driscoll@hp.com
#
# Updates:	v0.5	driscolj	intital script created
#
# VARIABLES
OLDLINE=""
DATA1=data1.out
DATA2=data2.out
COUNT=1
[ -f $DATA1 ] && rm $DATA1
[ -f $DATA2 ] && rm $DATA2
DEBUG=0
#

# Begin
echo file = $1

# generate parsed file without duplicate lines
cat $1 |egrep "Device Symmetrix Name    :|Blocks      :" | sed 's/^[ \t]*//'| uniq> $DATA1

# get the number of lines to process
TOTALCOUNT=`cat $DATA1 | wc -l`

# loop through every line in the parsed output
while read line 
 do
	# read in the first word of the current line as a variable 
	TYPE=`echo $line | awk '{print $1}'`
	[ $DEBUG = "1" ] && echo type = $TYPE
	# if the line is a device, then.....
	if [ $TYPE = "Device" ]
	 then
		# this is a device
		# store the value for later
		 DEVICE=`echo "$line" | awk -F: '{print $2}' | sed 's/^[ \t]*//'|sed 's///'`
		[ $DEBUG = "1" ] && 	echo device = $DEVICE
	fi

	# if the line is a capacity, then...
	if [ $TYPE = "512-byte" ] 
	 then
		# this is a capacity
		CAPACITY=`echo $line | awk -F: '{print $2}' | sed 's/^[ \t]*//'`
		[ $DEBUG = "1" ] && echo "      Device = $DEVICE, capacity = $CAPACITY"
		echo "${DEVICE}, ${CAPACITY}" >> $DATA2
	fi	

# display some progress.....
echo $COUNT / $TOTALCOUNT
COUNT=$(( $COUNT + 1 ))

# repeat until done!
done < $DATA1

### The end!

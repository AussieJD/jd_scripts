#!/bin/bash
#
# Script to look for duplicate checksums in a folder (recursively) in order to find duplicate files
#
# Usage:
#
# Date:		19-Aug-2007	jd: created
#
# VARIABLES
COUNT=1
ITEMS=0
OUTFILE=file-list.out
OUTFILE2=file-list-checked.out
#EXCLUDE=DS_Store|exists
#
# SCRIPT
[ -f $OUTFILE ] && rm $OUTFILE
[ -f $OUTFILE2 ] && rm $OUTFILE2
# create checksums - redirect standard error to /dev/null
find . | egrep -v '(DS_Store|exists)' | while read filename;do cksum ${filename} >> $OUTFILE 2> /dev/null ;done
ITEMS=`cat $OUTFILE | wc -l`
echo items=$ITEMS
#COUNT2=$(($COUNT+
#while [ ${COUNT} -le ${ITEMS} ]
#do
for i in `cat $OUTFILE | awk '{print $1}'`
do
	echo "Line: $COUNT - $i - `grep $i $OUTFILE | awk '{print $3}'`" | tee -a $OUTFILE2
	cat -n file-list.out | grep $i | grep -v $COUNT| tee -a $OUTFILE2
	COUNT=$(($COUNT + 1)) 
done
#	if [  $VAR2 -ne $COUNT ]
#	then
#		echo yay
#		#VAR3=`cat -n $OUTFILE | grep "${VAR}"`
#		VAR3=`cat -n $OUTFILE`
#	fi
#done
##
#The End!

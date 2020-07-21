#!/bin/bash
#
# Backup JD's Files to DVD
##
BASE=/Volumes/JD
LISTFILE=$BASE/scripts/dvdbackup.list

##

LIST=(`cat $LISTFILE | grep -v "#"`)

##

SUM=0
count=1
for i in ${LIST[@]}; do
	VAR=`du -ks $BASE/$i`
	SUM2=`echo $VAR | awk '{print $1}'`
	SUM=$(($SUM + $SUM2))
	printf "$i - $SUM2 - $SUM\n"
	count=$(($count + 1 ))
done
printf "\n"

SUMGB=$(($SUM/1000000))
SUMGB2=$(($SUM%1000000))
echo "Total size is $SUMGB.$SUMGB2 GB"

## The End!

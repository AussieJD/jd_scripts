#!/usr/bin/bash

# Make sure we can see the SAN disks listed in /UVH/etc/uvh-disks

# VARIABLES #########################################

LIST="auszvuvh001 auszvuvh004"	# 6-Mar-2014 removed 002, 003, 005
TMP=/tmp/FORMAT.$$
BASE=/UVH
FILE=$BASE/etc/uvh-disks
VAR1=SAN-w

BASE=/UVH

# SCRIPT #############################################
 
clear
echo "UVH SAN disk check"
printf "%-38s %-6s %-15s %-8s %-7s \n" DISK SIZE ALLOCATION Label Result
printf "%-38s %-6s %-15s %-7s \n" ---- ---- ----- ------

echo | format > $TMP

cat /UVH/etc/uvh-disks | grep $VAR1 | while read line 
 do 
	DISK=`echo $line | awk '{print $1}'`
	SIZE=`echo $line | awk '{print $2}'`
	ALLOCATION=`echo $line | awk '{print $3}'`
	label=`cat $TMP | grep $DISK | awk '{print $12}'`
	[ ! $label ] && label="no_label"

	cat $TMP | grep $DISK > /dev/null 2>&1
	[ $? = 0 ]	&& result="found in format" \
			|| result="missing"

	printf "%-38s %-6s %-15s %-8s %-7s\n" $DISK $SIZE $ALLOCATION $label "$result"

done

[ -f $TMP ] && rm $TMP

printf "\n%-10s %-10s %-10s %-5s %-5s \n" Size Wave1 Wave2 Total "Sum(G)"
sumtot=0
sum=0

for i in 50G 100G 150G 500G 1000G
 do
	w1=`cat $FILE | grep ${VAR1}1 | grep -v release | grep " $i" | wc -l`
	w2=`cat $FILE | grep ${VAR1}2 | grep -v release | grep " $i" | wc -l`
	total=`echo "$w1+$w2" | bc`
	size=`echo $i | sed "s/.$//"`
	sum=`echo "$total*$size" | bc `
	sumtot=`echo $sumtot+$sum | bc`


	printf "%-10s %-10s %-10s %-5s %-5s \n" $i $w1 $w2 $total $sum
done

printf "%30s %12s\n" Total: $sumtot




#The End!


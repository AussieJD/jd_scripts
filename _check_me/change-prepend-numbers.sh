#!/bin/ksh
#
# Usage:	Add numbers to the front of files/folders in specific order
#
# Created 	j.driscoll	Oct 2002
#
count=1
for i in *album
 do
	echo $i
	one=`echo $i | cut -f2,3 -d.`
	echo $one
	if [ $count -lt 10 ]; then prefix=00; elif [ $count -lt 100 ]; then prefix=0; else prefix=;fi
	echo $prefix$count.$one
#	mv $i $prefix$count.$one
	count=$(($count+1))
done


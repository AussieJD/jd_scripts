#!/bin/bash
#
# Summary:	monitor the copy of a large file, giving stats on transfer rate, time remaining etc...
#
# Usage:	jd-copy-progress.sh original-file destination-file
#
#
orig=$1
dest=$2
echo "Original:		$orig"
echo "Destination:		$dest"
destsize=0

origsize=`du -ks $orig |awk '{print $1}'`

while true
 do
	destsizeold=$destsize
	destsize=`du -ks $dest | awk '{print $1}'`
	diff=`echo $origsize - $destsize | bc`			# overall remaining
	diffmb=`echo $diff / 1024 | bc`			# overall remaining
	change10=`echo $destsize - $destsizeold |bc`		# change in 10 sec
	change1=`echo $change10 / 10 | bc`			# change in 1 sec
#	S6=`echo $S4 / 1024 | bc`		# kB in 1 sec
#	S7=`echo $S3 / $S5 | bc`		# seconds remaining
#	S8=`echo $S7 / 60|bc`			# minutes remaining
#	S9=`echo $S8 / 60 | bc`			# hours remaining
#	echo "remaining: $S3 (at ${S5}k per sec)(${S6}kB/s)($S8 minutes)($S9 hours)"
#
clear
	echo " Original:	$origsize (${orig})"
	echo " Destination:	$destsize (${dest})"
	echo "remaining: $diffmb (at ${change1}k per sec)(${S6}kB/s)($S8 minutes)"
#
	echo $origsize, $destsize 
	sleep 10
done
#
# The End!

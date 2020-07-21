#!/bin/bash
#
# ping google and display latency as a bar graph
BASE=~/scripts/dropbox-scripts
while true
 do
#	PINGOUT=`ping -c 1 -t 1 www.google.com | grep "bytes from" | awk -F= '{print $4}'|awk -F. '{print $1}'`
#	echo pingout=$PINGOUT
#
	DATE1=`date +%Y%m%d-%H:%M`
	PINGOUT=`$BASE/bar1.sh \`ping -c 1 -t 3 www.google.com | grep "bytes from" | awk -F= '{print $4}'|awk -F. '{print $1}'\` 2`
[ $? = 0 ] && echo "$DATE1 (www.google.com): $PINGOUT" || echo "----- miss"
sleep 2
done
# The End!

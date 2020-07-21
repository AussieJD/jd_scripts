#!/bin/bash
#
# Check which disk has been booted from
#  - if it is the right disk do nothing
#  - if it is the wrong disk, email
#
# Start
var1=`df -h | grep -v ^Filesystem | head -1 | awk '{print $1}'`
#
if [ $var1 = "/dev/disk0s2" ] 
 then	
	#echo "ok"
	echo "INFO: iMac27 is booted from CORRECT boot disk ($var1)" | mailx \
	-s "INFO: iMac27 is booted from correct boot disk $var1" jon@driscoll.com
 else
	var2=`df -h | grep "/dev/disk0s2" | awk '{print $9}'`
	echo "WARNING: iMac27 is booted from $var1 = (and not $var2, /dev/disk0s2)" | mailx \
	-s "WARNING:iMac27 is booted from strange boot disk" jon@driscoll.com
fi
	





# The End!

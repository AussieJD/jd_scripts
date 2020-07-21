#!/bin/bash
#
while true
 do 	
	S2old=$S2
	S2=`du -ks /Volumes/JDRAID1/virtualbox/JD-32813.asiapacific.hpqcorp.net.vdi|awk '{print $1}'`
	S1=`du -ks /Volumes/JDRAID1/virtualbox/JD-32813.asiapacific.hpqcorp.net.vmdk | awk '{print $1}'`
	S3=`echo $S2 - $S1| bc`			# difference
	S4=`echo $S2 - $S2old|bc`		# change in 10 sec
	S5=`echo $S4 / 10|bc`			# change in 1 sec
	S6=`echo $S4 / 1024 | bc`		# kB in 1 sec
	S7=`echo $S3 / $S5 | bc`		# seconds remaining
	S8=`echo $S7 / 60|bc`			# minutes remaining
#	S9=`echo $S8 / 60 | bc`			# hours remaining
#	echo "remaining: $S3 (at ${S5}k per sec)(${S6}kB/s)($S8 minutes)($S9 hours)"
	echo "remaining: $S3 (at ${S5}k per sec)(${S6}kB/s)($S8 minutes)"
	echo $S2, $S1 
	sleep 10
done

#!/bin/bash
#
for i in `ls create?.sh`
 do
	echo "file = $i"
	./$i
	sleep 2 
done

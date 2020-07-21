#!/bin/bash
#
for i in `ls update*`
 do
	./$i
	sleep 2 
done

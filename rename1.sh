#!/bin/bash
#
# rename (append text) to files in a folder based on contents
#
var1=$1

for F in $(ls | grep -v $1)
 do
	if grep "$1" "$F"
	 then
		NEW=${F:0:11}.$1-${F:11}
		echo $NEW
		break
	fi
done
	


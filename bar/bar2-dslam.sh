#!/bin/bash
#
# ping google and display latency as a bar graph

#HOST=121.45.67.214
HOST="192.168.1.254 192.231.203.132 192.231.203.3 8.8.8.8"

while true
 do
	echo "----------------"
#	for i in 192.231.203.132 192.231.203.3 8.8.8.8
	for i in $HOST
	 do
		DATE1=`date +%Y/%m/%d-%H.%M`
		PINGTIME=`ping -c 1 -t 2 $i | grep "bytes from" | awk -F= '{print $4}'|awk -F. '{print $1}'`
		PINGOUT=`./bar1.sh $PINGTIME 2`
		string1="${DATE1} ($i):"
		string2=$PINGOUT
		pad=$(printf '%0.1s' "-"{1..20})
		padlength=10
		line="-------------------------------------"
#		[ $? = 0 ] && echo "$DATE1 	($i)		$PINGOUT " || echo "----- miss"
#		printf '%s%*.*s%s\n' "$string1" 0 $((padlength - ${#string1} - ${#string2} )) "$pad" "$string2"
#		printf '%s%*.*s%s\n' "$string1" 0 $((padlength - ${#string1} )) "$pad" "$string2"
		printf "%s %s %s %s %s \n" $string1 ${line:${#string1}} $string2
	done

	sleep 2
done

# The End!

#!/bin/bash
#
BASE=.
BASE2=./bar
#BAR=bar1.sh
BARLENGTH=3			# modify length of bars 
####################################
clear
echo "Time				Router		Internode 	Google	Router"
echo "====				======    	========= 	====== 	======" 	
while true
 do
	mytime=`date +%Y-%m-%d" "%r`
	myping=`ping -t 1 -c 1 8.8.8.8 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` 
	myping2=`ping -t 1 -c 1 192.231.203.132 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` 
	myping3=`ping -t 1 -c 1 192.168.1.254 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` 
	myping_1=`echo $myping| awk '{print $1}'`
	[ -f "$BASE2/$BAR" ] && bar1=`$BASE2/$BAR $myping_1 $BARLENGTH`

#	[ ! ${myping} ] && myping="---"
#	[ ! ${myping2} ] && myping2="---"
#	[ ! ${myping3} ] && myping3="---"

	printf "$mytime	\t$myping3	$myping2	$myping $bar1\n"
	
	sleep 10
done


# The End!

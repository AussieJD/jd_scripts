#!/bin/bash
#
# /Users/jon/OneDrive/1. JD's Onedrive Files/01_JD_Docs/_Computer-specific/_scripts master
BASE2=./bar
BAR=bar1.sh
BARLENGTH=3			# modify length of bars 
#
NAME1="Router"; IP1=192.168.1.254
NAME2="AIMESH"; IP2=192.168.1.193
NAME3="Internode"; IP3=192.231.203.132
NAME4="Google"; IP4=8.8.8.8
NAME5="Google_Bars"

####################################

clear
# check local folder  - later
clear
printf "%-30s %-15s %-15s %-15s %-15s %-15s \n" Time $NAME1 $NAME2 $NAME3 $NAME4 $NAME5
printf "%-30s %-15s %-15s %-15s %-15s %-15s \n" ---- "[$IP1" "$IP2]" $IP3 $IP4 ----
printf "%-135s \n" ------------------------------------------------------------------------------------------------------------------------ 
while true
 do
	mytime=`date +%Y-%m-%d" "%r`
	myping1="1000"
	myping2="1000"
	myping3="1000"
	myping4="1000"

#	ping -c1 $IP1 > /dev/null 2>&1 		&& myping1=`ping -t 2 -c 1 $IP1 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'`  \
#						|| myping1="xxx" 
	myping1=`ping -t 2 -c 1 $IP1 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` > /dev/null 2>&1   || myping1="xxx" 


#	ping -c1 $IP2 > /dev/null 2>&1 		&& myping2=`ping -t 2 -c 1 $IP2 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'`  \
#						|| myping2="xxx" 
	myping2=`ping -t 2 -c 1 $IP2 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` > /dev/null 2>&1   || myping2="xxx" 

#	ping -c1 $IP3 > /dev/null 2>&1 		&& myping3=`ping -t 2 -c 1 $IP3 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'`  \
#						|| myping3="xxx" 
	myping3=`ping -t 2 -c 1 $IP3 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'` > /dev/null 2>&1   || myping3="xxx" 

#	ping -c1 $IP4 > /dev/null 2>&1 		&& { myping4=`ping -t 2 -c 1 $IP4 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'`;  \
#						   myping4a=`echo $myping4 | awk '{print $1}'`; \
#						   [ -f "$BASE2/$BAR" ] && bar1=`$BASE2/$BAR $myping4a $BARLENGTH`; }  \
#						|| { myping4="xxx" ; bar1="error";  }
	{ myping4=`ping -t 2 -c 1 $IP4 | egrep '(icmp_seq)'| awk -F"=" '{print $4}'`;  \
						   myping4a=`echo $myping4 | awk '{print $1}'`; \
						   [ -f "$BASE2/$BAR" ] && bar1=`$BASE2/$BAR $myping4a $BARLENGTH`; }  \
						|| { myping4="xxx" ; bar1="error";  }

	printf "%-30s %-15s %-15s %-15s %-15s %-15s \n" "$mytime" "[ $myping1" "$myping2 ]" "$myping3" "$myping4" "$bar1"

	
	sleep 10
done


# The End!

#!/usr/bin/env bash
#
# /Users/jon/OneDrive/1. JD's Onedrive Files/01_JD_Docs/_Computer-specific/_scripts master

##clear

#echo $LINES_TO_SHOW lines...
[ ! "$1" ] && echo "usage: $0 <lines to show> " && exit 0

LINES_TO_SHOW=$1
echo "$LINES_TO_SHOW" lines...

BASE2=./bar
BAR=bar1.sh
BARLENGTH=1			# 1=one to one, 2 = divide by 2, 3=divide by 3 .. etc..
#
NAME1="Router"; IP1=192.168.1.254
NAME2="AIMESH"; IP2=192.168.1.193
NAME3="Internode"; IP3=192.231.203.132
NAME4="Google"; IP4=8.8.8.8

####################################

while true
 do
	mytime=$(date +%y-%m-%d" "%T)
	myping="1000"
	clear


##1	count1=1
	for i in "$IP1" "$IP2" "$IP3" "$IP4" ;
	do
##1		echo "$count1" $i
		myping=$(ping -t 2 -c 1 "$i" | grep -E '(icmp_seq)'| awk -F"=" '{print $4}'|cut -d" " -f1 |cut -d. -f1 | bc)
		#myping=$(ping -t 2 -c 1 "$i" | grep -E '(icmp_seq)'| awk -F"=" '{print $4}'|cut -d" " -f1 |cut -d. -f1 | bc)
##2		echo  myping=$myping
		if [ "$myping" ] 
		 then
		        [ $myping -gt "100" ] && mypingb=100 || mypingb=$myping     
		        [ -f "$BASE2/$BAR" ]   && bar=$($BASE2/$BAR "$mypingb" "$BARLENGTH")  
		        [ $myping -gt "100" ] && bar=${bar}_xx_$myping                
		
		 else
		        myping="xxx"; bar="error"
		fi

		printf "%-16s %-20s %-15s %-15s \n" "$i" "$mytime" "$myping ms" "$bar" >> _data/${i}.log
##1		count1=$(( count1 + 1 ))
	done

	# print all
	echo "$NAME1 ---"
	tail -"$LINES_TO_SHOW" _data/${IP1}.log
	echo "$NAME2 ---"
	tail -"$LINES_TO_SHOW" _data/${IP2}.log
	echo "$NAME3 ---"
	tail -"$LINES_TO_SHOW" _data/${IP3}.log
	echo "$NAME4 ---"
	tail -"$LINES_TO_SHOW" _data/${IP4}.log

	sleep 10
done


# The End!

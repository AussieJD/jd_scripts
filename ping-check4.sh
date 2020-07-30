#!/usr/bin/env bash
#
# /Users/jon/OneDrive/1. JD's Onedrive Files/01_JD_Docs/_Computer-specific/_scripts master

##clear

#echo $LINES_TO_SHOW lines...
[ ! "$1" ] && echo "usage: $0 <lines to show> " && exit 0

LINES_TO_SHOW=$1
echo "$LINES_TO_SHOW" lines...

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BASE2=./bar
LOGFILE_FOLDER_LOCAL="$HOME/_ping_check_data_logs"
LOGFILE_TRANSFER_KEY=$LOGFILE_FOLDER_LOCAL/last_transfered_log
LOGFILE_FOLDER_ONLINE=$DIR/_data
BAR=bar1.sh
BARLENGTH=1			# 1=one to one, 2 = divide by 2, 3=divide by 3 .. etc..
BAR_ZOOM_IN=5			# multiply "small" results to get better graphs
#
NAME1="Router"; IP1=192.168.1.254; ZOOM1=5
NAME2="AIMESH"; IP2=192.168.1.193; ZOOM2=5
NAME3="Internode"; IP3=192.231.203.132; ZOOM3=3
NAME4="Google"; IP4=8.8.8.8; ZOOM4=1

# prepare log folder
[ ! -d "$LOGFILE_FOLDER_LOCAL" ] && mkdir "$LOGFILE_FOLDER_LOCAL"
[ ! -d "$LOGFILE_FOLDER_ONLINE" ] && mkdir "$LOGFILE_FOLDER_ONLINE"
[ ! -f "$LOGFILE_TRANSFER_KEY" ] && touch "$LOGFILE_TRANSFER_KEY"

# RFE -  roll logs to online drive 
#funtion arguments -> filename to comapre against curr time

MAXAGE=$(bc <<< '30*24*60*60') # seconds in 30 days
# file age in seconds = current_time - file_modification_time.
FILEAGE=$(( $(date +%s) - $(stat -f "%m" "$LOGFILE_TRANSFER_KEY")))
#echo Max="$MAXAGE"
#echo FILEAGE="$FILEAGE"
if [ "$FILEAGE" -lt "$MAXAGE" ] 
 then
	echo "... leaving logs in local folder"
 else
        echo "... moving logs to online drive"
	cp -rf "$LOGFILE_FOLDER_LOCAL"/* "$LOGFILE_FOLDER_ONLINE"/
	touch -m "$LOGFILE_TRANSFER_KEY"
fi
	

####################################

while true
 do
	mytime=$(date +%y-%m-%d" "%T)
	myping="1000"


##1	count1=1
	for i in "$IP1" "$IP2" "$IP3" "$IP4" ;
	do
##1		echo "$count1" $i
		myping=$(ping -t 2 -c 1 "$i" | grep -E '(icmp_seq)'| awk -F"=" '{print $4}'|cut -d" " -f1 |cut -d. -f1 | bc)
		#myping=$(ping -t 2 -c 1 "$i" | grep -E '(icmp_seq)'| awk -F"=" '{print $4}'|cut -d" " -f1 |cut -d. -f1 | bc)
##2		echo  myping=$myping
		if [ "$myping" ] 
		 then
		        [ "$myping" -gt "100" ] && mypingb=100 || mypingb=$myping     
		        [ -f "$BASE2/$BAR" ]   && bar=$($BASE2/$BAR "$mypingb" "$BARLENGTH")  
		        [ "$myping" -gt "100" ] && bar=${bar}_xx_$myping                
		
		 else
		        myping="xxx"; bar="error"
		fi

		printf "%-16s %-20s %-15s %-15s \n" "$i" "$mytime" "$myping ms" "$bar" >> "$LOGFILE_FOLDER_LOCAL"/"${i}".log
##1		count1=$(( count1 + 1 ))
	done

# averages
	router_total_records=$( grep -vc "xxx" < "$LOGFILE_FOLDER_LOCAL/${IP1}.log" )
	router_total_sum=$( sum=0;for i in $(cat "$LOGFILE_FOLDER_LOCAL/${IP1}.log"| awk -F" " '{print $4}' | grep -v xxx) ; do sum=$(( "$sum" + "$i" ));done;echo "$sum" )
	router_average=$(( router_total_sum / router_total_records ))
	[ -f "$BASE2/$BAR" ]   && router_av_bar=$($BASE2/$BAR "$router_average" "$BARLENGTH")
	router_av_bar=$( echo "${router_av_bar}" | sed 's/|/>/g' )

	aimesh_total_records=$( grep -vc "xxx" < "$LOGFILE_FOLDER_LOCAL/${IP2}.log" )
	aimesh_total_sum=$( sum=0;for i in $(cat "$LOGFILE_FOLDER_LOCAL/${IP2}.log"| awk -F" " '{print $4}' | grep -v xxx) ; do sum=$(( "$sum" + "$i" ));done;echo "$sum" )
	aimesh_average=$(( aimesh_total_sum / aimesh_total_records ))
	[ -f "$BASE2/$BAR" ]   && aimesh_av_bar=$($BASE2/$BAR "$aimesh_average" "$BARLENGTH")
	aimesh_av_bar=$( echo "${aimesh_av_bar}" | sed 's/|/>/g' )

	internode_total_records=$( grep -vc "xxx" < "$LOGFILE_FOLDER_LOCAL/${IP3}.log" )
	internode_total_sum=$( sum=0;for i in $(cat "$LOGFILE_FOLDER_LOCAL/${IP3}.log"| awk -F" " '{print $4}' | grep -v xxx) ; do sum=$(( "$sum" + "$i" ));done;echo "$sum" )
	internode_average=$(( internode_total_sum / internode_total_records ))
	[ -f "$BASE2/$BAR" ]   && internode_av_bar=$($BASE2/$BAR "$internode_average" "$BARLENGTH")
	internode_av_bar=$( echo "${internode_av_bar}" | sed 's/|/>/g' )

	goog_total_records=$( grep -vc "xxx" < "$LOGFILE_FOLDER_LOCAL/${IP4}.log" )
	goog_total_sum=$( sum=0;for i in $(cat "$LOGFILE_FOLDER_LOCAL/${IP4}.log"| awk -F" " '{print $4}' | grep -v xxx) ; do sum=$(( "$sum" + "$i" ));done;echo "$sum" )
	goog_average=$(( goog_total_sum / goog_total_records ))
	[ -f "$BASE2/$BAR" ]   && goog_av_bar=$($BASE2/$BAR "$goog_average" "$BARLENGTH")
	goog_av_bar=$( echo "${goog_av_bar}" | sed 's/|/>/g' )

# print all
	printf "%-53s %-40s < [ average: %-3s ms] \n" "$NAME1 ---" "$router_av_bar" "$router_average"
	tail -"$LINES_TO_SHOW" "$LOGFILE_FOLDER_LOCAL"/"${IP1}".log
	printf "%-53s %-40s \n" "$NAME1 ---" "$router_av_bar" 
	echo

	printf "%-53s %-40s < [ average: %-3s ms] \n" "$NAME2 ---" "$aimesh_av_bar" "$aimesh_average"
	tail -"$LINES_TO_SHOW" "$LOGFILE_FOLDER_LOCAL"/"${IP2}".log
	printf "%-53s %-40s \n" "$NAME2 ---" "$aimesh_av_bar" 
	echo
	
	printf "%-53s %-40s < [ average: %-3s ms] \n" "$NAME3 ---" "$internode_av_bar" "$internode_average"
	tail -"$LINES_TO_SHOW" "$LOGFILE_FOLDER_LOCAL"/"${IP3}".log
	printf "%-53s %-40s \n" "$NAME3 ---" "$internode_av_bar" 
	echo
	
	printf "%-53s %-40s < [ average: %-3s ms] \n" "$NAME4 ---" "$goog_av_bar" "$goog_average"
	tail -"$LINES_TO_SHOW" "$LOGFILE_FOLDER_LOCAL"/"${IP4}".log
	printf "%-53s %-40s \n" " ---" "$goog_av_bar" 

	sleep 10
	clear
done


# The End!

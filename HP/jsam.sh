#!/bin/bash
#
# ssh to HP DCT UVH from non windows host
#
# Usage: set-screensharing-resolution.sh <machine>  <number from 1 to 5>
#
# - reads a list from wsam.conf for options
#
CONF_FILE="jsam.conf"
SSH_APP="/Applications//iTerm.app"
USER=cz0qk6

clear

echo "Select session to start:
1)	auszvuvh001
2)	auszvuvh002
3)	auszvuvh003
4)	auszvuvh004
5)	auszvuvh005
6)	auszvuvh006"
echo -n "7)	 all		Select: [7]>"
read NUM
[ ! $NUM ] && NUM=7

case $NUM in

	1 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
		ssh $USER@$IP
	;;

	2 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
	;;

	3 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
	;;

	4 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
	;;

	5 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
	;;

	6 ) 	IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...ssh to auszvuvh00${NUM} ($IP)"
	;;

	7 ) 	#IP=`cat $CONF_FILE | grep -v ^# | grep -i auszvuvh00${NUM} | awk '{print $3}'`
		echo "...not implemented"
	;;


esac
	

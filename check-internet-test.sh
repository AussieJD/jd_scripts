#!/bin/bash
#
#
#
## Check if internet changes state ######
#
# Usage:
#	- sets up=yes or up=no
#	- sets changed=yes or changed-no
#	- announces when internet was down and has come up
#	- announces if internet is down every X seconds
#	- only announces internet up every hour
#
#
#
## Variables #############################

PREVIOUS_FILE=/tmp/internet-status-previous
SITE1=8.8.8.8
SITE2=192.168.1.254
voice=Bad		# use `say -v ?` to find voices
WAIT=10

#
## Functions ################################

function static-variables(){

#$1=debug
debug=			# set debug to "yes" to echo variables
WAIT=10
current=down
previous=down

}

 function once(){
	[[ -f $PREVIOUS_FILE ]] && previous=`cat $PREVIOUS_FILE` || previous=down
	/sbin/ping -t 2 $SITE1 >/dev/null 2>&1
	[[ $? = "0" ]] && current=up || current=down
	[[ $debug = "yes" ]] && echo current=$current, previous=$previous
	[[ $current = "up" && $previous = "down" ]] && say "Internet is back up" && echo "up" > $PREVIOUS_FILE 
	[[ $current = "down" && $previous = "up" ]] && say -v $voice "Internet has gone down" && echo "down" > $PREVIOUS_FILE 
	[[ $current = "down" && $previous = "down" ]] && say -v Whisper Internet is still down
 }

#function loop(){
while true
 do
	say "ping"
	ping -t 1 8.8.8.8 > /dev/null 2>&1
	[[ $? = 0 ]] && say Internet is up || say Internet is down 
sleep 10
done
#}

#
## Script ##################################

#loop		# function



#
## The End! #############################

#!/bin/bash
#
# check VOIP status in billion modem (uses separate expect script to log in)
#
CHECK=registered  	# WHAT WE'RE LOOKING FOR
#CHECK=bogus

#### Set up counters and variables ##########################

#MYPATH=~/Dropbox/JD/computer-stuff/scripts/billion
#MYPATH=/Users/jon/Dropbox/JD/computer-stuff/scripts/billion
MYPATH=/Volumes/data/Users/jon/Dropbox/JD/computer-stuff/scripts/billion

# define the log file that captures how many "times" the router is not reachable...
# if log file does not exist, create a new one and initialise counters
COUNT_UNREACHABLE_FILE=/tmp/billion-check-unreachable-count.out
[ ! -f $COUNT_UNREACHABLE_FILE ] && echo "1 1" > $COUNT_UNREACHABLE_FILE

# initialise counter  variables from log file

COUNT_UNREACHABLE=`cat $COUNT_UNREACHABLE_FILE | awk '{print $1}'`
COUNT_UNREACHABLE2=`cat $COUNT_UNREACHABLE_FILE | awk '{print $2}'`

# define the log file that captures how many "times" the VOIP service is "unregistered"
# if log file does not exist, create a new one and initialise counters

COUNT_UNREGISTERED_FILE=/tmp/billion-check-unregistered-count.out
[ ! -f $COUNT_UNREGISTERED_FILE ] && echo "1 1" > $COUNT_UNREGISTERED_FILE

# initialise counter variables from log file

COUNT_UNREGISTERED=`cat $COUNT_UNREGISTERED_FILE | awk '{print $1}'`
COUNT_UNREGISTERED2=`cat $COUNT_UNREGISTERED_FILE | awk '{print $2}'`

#### 

# check if modem visible via ping
/sbin/ping -c 1 192.168.1.249
if [ $? -eq 0 ] 
 then 	echo "router reachable .. continuing VOIP check"
	echo "1 1" > $COUNT_UNREACHABLE_FILE
 else 	echo "router unreachable ... checking failure counts"
	if [ $COUNT_UNREACHABLE -lt 5 ] 
	 then 
		echo "... failure count is less than 5 - emailing JD"
		echo "... can not ping VOIP router" | mailx -s "VOIP router unreachable ($COUNT_UNREACHABLE) - `date +%F" - "%a" "%d" "%b" "%H:%m`" jon@driscoll.com 
		COUNT_UNREACHABLE=$(( $COUNT_UNREACHABLE + 1 ))
		echo $COUNT_UNREACHABLE $COUNT_UNREACHABLE2 > $COUNT_UNREACHABLE_FILE
	 else 
		echo "... failure count is more than 5 - emailing JD less often"
		COUNT_UNREACHABLE=$(( $COUNT_UNREACHABLE + 1 ))
		if [ $COUNT_UNREACHABLE2 -lt 6 ]
		 then	$COUNT_UNREACHABLE2=$(( $COUNT_UNREACHABLE2 + 1 ))
			echo $COUNT_UNREACHABLE $COUNT_UNREACHABLE2 > $COUNT_UNREACHABLE_FILE
		 else
			echo "... can not ping VOIP router" | mailx -s "VOIP router unreachable ($COUNT_UNREACHABLE) - `date +%F" - "%a" "%d" "%b" "%H:%m`" jon@driscoll.com	
			echo $COUNT_UNREACHABLE 1 > $COUNT_UNREACHABLE_FILE
		fi
	fi
	exit 1 
fi
	

#log in and check VOIP connection status - if not registered, restart modem

$MYPATH/billion-login.sh | grep "$CHECK"
if [ $? -eq 0 ] 	
 then
	echo "registered: do nothing" 
 else
	echo "restarting modem" 
	$MYPATH/billion-restart.sh 
	echo "VOIP not registered... restarted VOIP router" | mailx -s "VOIP not registered - router restarted - `date +%F" - "%a" "%d" "%b" "%H:%m`" jon@driscoll.com
fi

# The End!

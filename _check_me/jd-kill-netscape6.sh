#!/bin/ksh
#
# Usage:	find and kill netscape 6
#
#		
### variables
BASE=/home/jd51229
SEARCHFOR=/usr/dist/share/netscape,v6.2.2/mozilla-bin
PROCESS=`ps -ef | grep 51229 | grep $SEARCHFOR |grep -v grep`
if [ ! $PROCESS ] 
 then
	echo "..netscape not running...exiting..";sleep 2;exit 0;fi
PROCESSTOKILL=`ps -ef | grep 51229 | grep $SEARCHFOR |grep -v grep|awk '{print $2}' `
### Script
clear
echo "
You are about to kill.... \n
$PROCESS \n
.. is this ok [(y)/n]..>\c"
read answer
[ ! $answer ] && answer=y
[ $answer = "Y" ] && answer=y
if [ $answer = "y" ]
	then
		echo "yes recieved, killing process now....."
		kill -9 $PROCESSTOKILL
	else
		echo "doing nothing and quitting...."
		exit 0
fi
# The end

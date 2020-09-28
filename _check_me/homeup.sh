#!/bin/sh
#
# Usage: poll @adl-ann-1 (modempool) for jd51229,adds ip address to hosts file (user:root) 
#
#
# Script: homeup.sh
#
# 02 Feb 2000	B.James		This script updates the /etc/hosts file on
#				my SWAN machine with the correct IP address.
#
# 29 Mar 2000	B.James		Changed the line that determines the IP
#				to ensure that the string does not start 
#				with a blank.
#
# 13 May 2000	J.Driscoll	Adopted this file from Brodie - thanks BJ.
#				running from cron (root) every 5 mins!
#
# 16 May 2000	J.Driscoll	if home machine is not dialled in, take the
#				entry out of the hosts file 
#
# Modifications
#
#
date=`date +'%d %b %Y' | awk '{print $1 "-" $2 "-" $3}'`
string="Jon"
hostname="otter"
debug="n"
#cnt=`/usr/local/bin/modems jd | grep "$string" | wc -l | awk '{print $1}'`
cnt=`finger @adl-ann-1 |grep jd51229|wc -l`
# a)if there is an entry for 51229, the above returns "1"
#   so, find out the IP address of the connection
# b)and if not, make sure that there are no entries in the hosts file
#   then exit!
if [ $cnt -eq 1 ]
then
	#ip=`/usr/local/bin/modems jd | grep "$string" | cut -d':' -f1` 
	ip=129.158.93.`finger @adl-ann-1 |grep jd51229|cut -d"." -f4`
else
	# 16 May 2000 - take existing entry out of hosts file
	cp /etc/inet/hosts /tmp/hosts.old
        cat /tmp/hosts.old | grep -v "$hostname" > /etc/inet/hosts
	# end 16 May
	exit 0
fi
# we are logged on, so now go do the changes to the hosts file
# (if debug=y then we do the changes to a temp file to check...)
if [ "$debug" = "n" ]
then
	cp /etc/inet/hosts /tmp/hosts.old
	cat /tmp/hosts.old | grep -v "$hostname" > /etc/inet/hosts
	echo "$ip\t$hostname " >> /etc/inet/hosts
	echo "$ip\t$hostname \t#JD's home machine is logged in!" 
else
        cp /etc/inet/hosts /tmp/hosts.old
        cat /tmp/hosts.old | grep -v "$hostname" > /tmp/hosts
        echo "$ip\t$hostname \t#JD's home machine is logged in!" >> /tmp/hosts
fi
#
# Cleanup and end
#
rm /tmp/hosts.old
#
# The End!
#

#!/bin/sh
#
# Description: Script to upload iCal calendars to SOCS
# based upon Apple script by carlo.ferroni@sun.com (May 2003)
#
# History:	May 2003, carlo.ferroni@sun.com original Applescript.
#		May 2003, tony.shoumack@sun.com shell script created.
#		Aug 2003, jon.driscoll@sun.com shell script copied to local.
#		Jul 2004, jon.driscoll@sun.com, added additional calendar 
#
#
# record env HTTP_PROXY

debug=y
base=/Applications/socs-sync
#base=~/scripts
origproxy=`env | grep HTTP_PROXY|cut -d= -f2`
HTTP_PROXY=
http_proxy=
CONVERT_TZ=$base/convert_tz.sh
CONVERT_PERMISSIONS=$base/convert_tz.sh

# calendar variables

#thePassword=$1
theUser=ag35447
theServer=gentle.singapore  # socs.aus?
thePassword=j00lie
mydate=`date +%d-%h-%y,%H:%M`

# if server not visible, exit

ping -c 1 -q $theServer >> /dev/null 2>&1
if [ $? = 1 ] ;
 then 
	echo "oops - can't see socs.aus.sun.com"
	echo "$mydate: sync failed - not able to contact $theServer (not on SWAN?)" >> $base/ical_sync.log
	exit 1
fi
echo "can see socs - will attempt to sync"


# calendars - local and remote

theSocsCalendar1=ag35447
theCalendar1=Work

theSocsCalendar2=ag35447:personal
theCalendar2=Home

#
## Log in to calendar server
#

temp=`curl http://$theServer/login.wcap?user=$theUser\&password=$thePassword > /tmp/CAFsyncTemp`
theSession=`fgrep 'var id' /tmp/CAFsyncTemp | sed -e s,\',,g -e 's,var id=,,'`
echo the session = $theSession

[ $debug = "y" ] && echo "one"
#
## start processing calendars
#


# calendar 1
[ $debug = "y" ] && echo "two"
curl http://$theServer/deleteevents_by_range.wcap?id=$theSession\&calid=$theSocsCalendar1
curl http://$theServer/deletetodos_by_range.wcap?id=$theSession\&calid=$theSocsCalendar1
cat ~/Library/Calendars/$theCalendar1.ics > /tmp/CAFsync$theCalendar1
cat /tmp/CAFsync$theCalendar1 | $CONVERT_TZ > /tmp/CAFsync${theCalendar1}_TZ
curl  -F Upload=\@/tmp/CAFsync${theCalendar1}_TZ http://$theServer/import.wcap?id=$theSession\&calid=$theSocsCalendar1\&content-in=text/calendar

# calendar 2
[ $debug = "y" ] && echo "three"
curl http://$theServer/deleteevents_by_range.wcap?id=$theSession\&calid=$theSocsCalendar2
curl http://$theServer/deletetodos_by_range.wcap?id=$theSession\&calid=$theSocsCalendar2
cat ~/Library/Calendars/$theCalendar2.ics > /tmp/CAFsync$theCalendar2
cat /tmp/CAFsync$theCalendar2 | $CONVERT_TZ | $CONVERT_PERMISSIONS > /tmp/CAFsync${theCalendar2}_TZ
curl  -F Upload=\@/tmp/CAFsync${theCalendar2}_TZ http://$theServer/import.wcap?id=$theSession\&calid=$theSocsCalendar2\&content-in=text/calendar

# calendar 3
#[ $debug = "y" ] && echo "four"
#curl http://$theServer/deleteevents_by_range.wcap?id=$theSession\&calid=$theSocsCalendar3
#curl http://$theServer/deletetodos_by_range.wcap?id=$theSession\&calid=$theSocsCalendar3
#cat ~/Library/Calendars/$theCalendar3.ics > /tmp/CAFsync$theCalendar3
##cat /tmp/CAFsync$theCalendar3 | ~/scripts/convert_tz.sh > /tmp/CAFsync${theCalendar3}_TZ
#cat /tmp/CAFsync$theCalendar3 |~/scripts/convert_tz.sh |~/scripts/convert_to_private.sh >/tmp/CAFsync${theCalendar3}_TZ
#curl  -F Upload=\@/tmp/CAFsync${theCalendar3}_TZ http://$theServer/import.wcap?id=$theSession\&calid=$theSocsCalendar3\&content-in=text/calendar

#
## clean up
#

#rm /tmp/CAFsync*

#
## Log out from SunONE calendar
#

#curl http://$theServer/logout.wcap?id=$theSession

#
## Update log
#
echo "$mydate: sync COMPLETED" >> $base/ical_sync.log

# the end!

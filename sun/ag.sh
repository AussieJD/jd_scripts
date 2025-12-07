#!/bin/sh
#
# Description: Script to upload iCal calendars to SOCS
# based upon Apple script by carlo.ferroni@sun.com (May 2003)
#
# History:    May 2003, carlo.ferroni@sun.com original Applescript.
#        May 2003, tony.shoumack@sun.com shell script created.
#        Aug 2003, jon.driscoll@sun.com shell script copied to local.
#        Jul 2004, jon.driscoll@sun.com, added additional calendar
#
#
# record env HTTP_PROXY

debug=y
#base=/Applications/socs-sync    # set me to where this script, and the 2  convert scripts are
base=~/scripts   # set me to where this script, and the 2  convert scripts are


# remove any proxy settings (temporarily)
origproxy=`env | grep HTTP_PROXY|cut -d= -f2`
HTTP_PROXY=
http_proxy=

# calendar variables

#thePassword=$1
theUser=ag35447
theServer=socs.aus  # socs.aus?
thePassword=j00lie        # enter your socs (ldap) password in plain text here
mydate=`date +%d-%h-%y,%H:%M`

# if server not visible, exit

ping -c 1 -q $theServer >> /dev/null 2>&1
if [ $? = 1 ] ;
 then
    echo "oops - can't see socs.aus.sun.com"
    echo "$mydate: sync failed - not able to contact $theServer (not on  SWAN?)" >> $base/ical_sync.log
    exit 1
fi
echo "can see socs - will attempt to sync"


# calendars - local and remote

theSocsCalendar1=ag35447
theCalendar1=fred

theSocsCalendar2=ag35447:personal
theCalendar2=Home


#
## Log in to calendar server
#

temp=`curl  http://$theServer/login.wcap?user=$theUser\&password=$thePassword >  /tmp/CAFsyncTemp`
theSession=`fgrep 'var id' /tmp/CAFsyncTemp | sed -e s,\',,g -e 's,var  id=,,'`
echo the session = $theSession

[ $debug = "y" ] && echo "one"
#
## start processing calendars
#

CONVERT_TZ=$base/convert_tz.sh
CONVERT_PRIVATE=$base/convert_to_private.sh

# calendar 1
[ $debug = "y" ] && echo "two"
[ $debug = "y" ] && echo "curl 1"
curl  http://$theServer/deleteevents_by_range.wcap?id=$theSession\&calid=$theSocsCalendar1
[ $debug = "y" ] && echo "curl "
curl  http://$theServer/deletetodos_by_range.wcap?id=$theSession\&calid=$theSocsCalendar1
# convert timezone
cat ~/Library/Calendars/$theCalendar1.ics > /tmp/CAFsync$theCalendar1
cat /tmp/CAFsync$theCalendar1 | $CONVERT_TZ >  /tmp/CAFsync${theCalendar1}_TZ
[ $debug = "y" ] && echo "curl 3"
curl  -F Upload=\@/tmp/CAFsync${theCalendar1}_TZ  http://$theServer/import.wcap?id=$theSession\&calid=$theSocsCalendar1\&content-in=text/calendar

# calendar 2
[ $debug = "y" ] && echo "three"
curl  http://$theServer/deleteevents_by_range.wcap?id=$theSession\&calid=$theSocsCalendar2
curl  http://$theServer/deletetodos_by_range.wcap?id=$theSession\&calid=$theSocsCalendar2
cat ~/Library/Calendars/$theCalendar2.ics > /tmp/CAFsync$theCalendar2
# convert timezone and convert to a private calendar
cat /tmp/CAFsync$theCalendar2 | $CONVERT_TZ | $CONVERT_PRIVATE  >/tmp/CAFsync${theCalendar2}_TZ
curl  -F Upload=\@/tmp/CAFsync${theCalendar2}_TZ  http://$theServer/import.wcap?id=$theSession\&calid=$theSocsCalendar2\&content-in=text/calendar


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


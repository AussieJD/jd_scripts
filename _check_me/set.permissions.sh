#!/bin/ksh
#
# Usage: *DEMO* - does nothing - shows how you would chmod file automatically!
#
( echo "
# This simple script will change the permissions and ownership of all
# the files in this directory.
#
#cd /net/williams/export/WWW/sunsa/docs/partner
#usern=`/usr/xpg4/bin/id -u -n`
#	echo The user is $usern
#for i in  `ls -al | grep $usern | awk '{ print $9 }'`
#do
#	echo Making file $i readable/editable by all...
#	chgrp staff $i
#	chmod 775 $i
##done
 " )

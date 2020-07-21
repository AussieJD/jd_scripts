#!/bin/ksh
#
# File name     : export.disk.usage.sh
#
# Author        : Jon Driscoll
#
# Date          : 8 Feb 1999
#
# Description   :
#
#		This script:
#		 - creates a list of daily disk usage information
#		 - creates a web-page(s) to easily track the changes 
#		 - email users when capacity is over certain %
#
# Usage         : export.disk.usage.sh
#
# Modifications :
#
# Variables Used:	i, j, k, l, m, BASEDIR, MACHINE, SCRIPT, LOGFILE, LOGFILE2
#			HTMLSTART, HTMLMIDDLE, HTMLEND, HTMLMASTER, TIMEDATE, STATSFILE
#
#### Create / add to stats list
#
STATSFILE=/export/spacecheck/statsfile
#
#
#### Essential Information:
#
BASEDIR=/export/spacecheck				# base directory
MACHINE=`uname -a | awk '{ print $2}'`
SCRIPT=`basename $0`
LOGFILE=$BASEDIR/${SCRIPT}.log				# log file to email to users
LOGFILE2=$BASEDIR/${SCRIPT}.log2			# log file to add to web page
HTMLSTART=$BASEDIR/HTMLstart				# beginning of HTML file
HTMLMIDDLE=$BASEDIR/HTMLmiddle				# changing log of findings
HTMLEND=$BASEDIR/HTMLend				# end of HTML file
HTMLMASTER=$BASEDIR/spacecheck.html			# final HTML page
TIMEDATE=`date +%m--%d-%h-%Y-%R`
#
#
#### Initial actions
#
rm $LOGFILE $LOGFILE2					# remove previous log files
echo >> $LOGFILE
echo `date` >> $LOGFILE					# date stamp the logs
echo >> $LOGFILE2
echo `date` >> $LOGFILE2				# date stamp the logs
k=`cat $BASEDIR/disks.to.check | awk '{ print $1}'`	# read which disks to check from a file
capacity=`cat $BASEDIR/disk.capacity.limit`		# read disk capacity limit from a file
#
#
#### Start the investigation process
#
DFMINUSK=/tmp/dfminusk.out
df -k / /opt /export >$DFMINUSK
for l in $k
 do
 m=`more  $DFMINUSK | grep $l | awk '{ print $6 }'`
 i=`more  $DFMINUSK | grep $l | awk '{ print $5 }'| awk -F% '{print $1}'`
 j=`more  $DFMINUSK | grep $l | awk '{ print $4 }'`
 k=`more  $DFMINUSK | grep $l | awk '{ print $2 }'`
if [ $i -ge  $capacity ]; then
  ( echo "    
	Disk usage of ${MACHINE}:$m is $i%.... CAPACITY LOW !!!!!!   
	This leaves only ${j} kb of free space on a ${k} kb partition..
	=====================================
	This message has been generated automatically by 
	/export/local/admin/export.disk.usage.sh.
	See http://sunsa.aus/links/space/spacecheck.html for more information.
	The upper limit for allowable space is currently set at $capacity.
	To change this, edit williams:/export/spacecheck/disk.capacity.limit.
		Thanks. 

  ") >> ${LOGFILE}
     ( echo "    Disk usage of ${MACHINE}:$m is $i%.... CAPACITY LOW !!!!!!") >> $LOGFILE2
	cat $LOGFILE |  mailx -s "${MACHINE}:$m CAPACITY LOW !" jon@adelaide 
   else ( echo "    Disk usage of ${MACHINE}:$m is $i% ... capacity is OK" ) >> $LOGFILE2
fi
done
#
### Add results of check to *web page* and recreate page
#
#
#mv $HTMLMIDDLE $HTMLMIDDLE.old
#cat $LOGFILE2 >   $HTMLMIDDLE
#cat $HTMLMIDDLE.old >> $HTMLMIDDLE
#cat $HTMLSTART > $HTMLMASTER
#chmod 775 $HTMLMASTER
#echo "<a href="http://sunsa.aus/links/space/williams.export.stats">Export detailed stats...</a>" >> $HTMLMASTER
#cat $HTMLMIDDLE >> $HTMLMASTER
#cat $HTMLEND >> $HTMLMASTER
#
#
#### Create /export usage stats for closer diagnosis
#
#echo $TIMEDATE
#DULIST=`ls -1 /export/local | grep -v apps | grep -v install`
#for p in $DULIST ; do du -ks /export/local/$p >> $BASEDIR/williams.export.stats/$TIMEDATE.stats
#done
#echo >> $BASEDIR/williams.export.stats/$TIMEDATE.stats
#du -ks /export/local/pub/tars/*  >> $BASEDIR/williams.export.stats/$TIMEDATE.stats
#
#
#
#
#
# The End!
#

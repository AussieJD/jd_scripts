#!/bin/ksh
#
# File name     : backup_daily.sh
#
# Author        : Brodie James 
#
# Date          : 26 June 1997
#
# Description   :
#
# This backup script performs a full backup of the machine using the
# dump command for the boot partition and tar for the /export
# partition.  The result is mailed to the the SEs.
#
# Usage         : backup_daily.sh
#
# Modifications :
#
# 14 Jan 98	B.James		Changes backup DIR from /export/applic/loantool
#				to /export/applic to include database.
#
# 4 Jan 99	B.James		Changed script to backup_daily.sh and altered
#				to backup home and applic from /export
#
# 11 Jan 99	B.James		Changed script to prompt admin to change the
#				weekend tapes on Fridays.
#
# 17 Jan 99     B.James         Added reporting information about the tape
#                               that is being used and chnaged the way
#                               the script writes to the log file.
#
# Essential Information:
#
#
debug="n"
host=`uname -n`
SCRIPT=`basename $0`
LOG=/tmp/${SCRIPT}.log
MAIL=`cat /export/local/admin/se.backup.list | awk '{print $1}'`
RDEV="/dev/rmt/0c"; export RDEV
NRDEV="/dev/rmt/0cn"; export NRDEV
FAILED=n
DIR=/export
FILES="applic home"
DAY=`date '+%a'`
tapefile=/export/local/admin/full.num
tapefiledaily=/export/local/admin/daily.num
tapenum=`cat $tapefile`
admin=`cat /export/local/admin/tapeadmin.list | awk '{print $1}'`
admin_name=`cat /export/local/admin/tapeadmin.list | awk '{print $2}'`
#
# Determine what tape is being written to here
#
thistape=`cat $tapefiledaily`
#
# Calculate next full backup tape number, tapes are from 6 to 10.
#
nexttape=`expr $tapenum - 5`
nexttape=`expr $nexttape % 5`
nexttape=`expr $nexttape + 6`
#
# Report debug information
#
if [ "$debug" = "y" ]
then
	echo LOG=$LOG
	echo MAIL=$MAIL
	echo DAY=$DAY
	echo FILES=$FILES
	echo tapefile=$tapefile
	echo tapenum=$tapenum
	echo admin=$admin
	echo admin_name=$admin_name
	echo nexttape=$nexttape
	echo $nexttape > $tapefile
fi
#
# Start, rewind the tape
#
{
echo ""
echo "Backup script started at `date`"
echo ""
echo "Using tape $host-$thistape"
echo ""
echo "Rewinding tape"
mt -f $RDEV rewind
echo ""
#
# Backup selected directories from /export
#
echo ""
if [ "$DAY" = "Tue" ]
then
	mt -f $RDEV rewind
	echo "Loantool backup for $DAY, over writing tape\n\n"
else
	echo "Loantool backup for $DAY, forward stepping tape to end\n\n"
	mt -f $RDEV rewind
	mt -f $NRDEV eom
	mt -f $NRDEV status
fi
cd $DIR
echo ""
echo ""
echo "Directories to be backed up from `uname -n`:${DIR};\n\n${FILES}\n\n"
echo "Start time: `date`\n\n"
#tar cvf - . | /usr/local/bin/gzip | dd bs=64k of=$NRDEV
tar cvbf 128 $NRDEV $FILES
#tar cbf 128 $NRDEV $FILES
result=$?
echo "**********result=$result"
if [ $result -ne 0 ]
then
        FAILED=y
        echo "\n*** /export backup FAILED !! ***"
        subject="BACKUP FAILED: $host $LOG"
else
        subject="BACKUP SUCCESSFUL: $host $LOG"
fi
#
#  Report the end time
#
echo "\n\nEnd time: `date`"
echo ""
echo ""
echo "Daily backups finished, rewinding tape"
mt -f $RDEV rewind
echo "Backup script finished at `date`"
} > $LOG 2>&1
#
# Mail status of backup to SEs
#
( head -100 ${LOG}; echo "  .\n  .\n  .\n"; tail -100 ${LOG}) | mailx -s "$subject" $MAIL
#
#
#
if [ "$DAY" = "Fri" ]
then
	#
	# Rewind and eject the tape
	#
        mt -f $RDEV rewind
	mt -f $RDEV offline
	#
	# Mail admin to change tape
	#
	echo $nexttape > $tapefile
	echo "\n\n$admin_name\n\nPlease change the tape in the williams server to williams-$nexttape'.\n\n\nThanks!" | mailx -s "TAPE CHANGE: $host" -c "$MAIL" $admin
fi
#
# The End!
#

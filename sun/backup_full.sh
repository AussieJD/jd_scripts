#!/bin/ksh
#
# File name     : backup_full.sh
#
# Author        : Brodie James - Systems Engineer
#
# Date          : 26 June 1997
#
# Description   :
#
# This backup script performs a full backup of the machine using the
# dump command for the boot partition and tar for the /export
# partition.  The result is mailed to the the SEs.
#
# Usage         : backup_full.sh
#
# Modifications :
#
# 4 Jan 99	B.James		Modified to include /opt to compressed tape
#				device
#
# 11 Jan 99     B.James         Changed script to prompt admin to change the
#                               daily tapes on Mondays.
#
# 17 Jan 99	B.James		Added reporting information about the tape
#				that is being used and chnaged the way
#				the script writes to the log file.
#
# 24 Dec 99	B.James		Changed /export backup to ufsdump and put
#				in check for length of the log file, only
#				email the first and last 100 lines.
#
# 28 Jan 2000	B.James		Changed /export backup to tar of specific
#				directories.
#
#
# Essential Information:
#
#
#
debug="y"
host=`uname -n`
script=`basename $0`
log=/tmp/${script}.log
mail=`cat /export/local/admin/se.backup.list | awk '{print $1}'`
admin=`cat /export/local/admin/tapeadmin.list | awk '{print $1}'`
admin_name=`cat /export/local/admin/tapeadmin.list | awk '{print $2}'`
tapefilefull=/export/local/admin/full.num
tapefile=/export/local/admin/daily.num
RDEV="/dev/rmt/0c"; export RDEV
NRDEV="/dev/rmt/0cn"; export NRDEV
FAILED=n
subject="BACKUP SUCCESSFUL: $host backup_full.sh.log"
#LOCALFILES=`cd /export; ls local/* | grep : | grep -v pub | cut -d: -f1`
#FILES="applic \
#home \
#install/autoinst \
#WWW \
#$LOCALFILES"
FILES="applic archives home install/autoinst local opt WWW"
#
# Determine what tape is being written to here
#
thistape=`cat $tapefilefull`
#
# Calculate next daily backup tape number, tapes are from 1 to 5.
#
tapenum=`cat $tapefile`
nexttape=`expr $tapenum % 5`
nexttape=`expr $nexttape + 1`
#
# Report debug information
#
if [ "$debug" = "y" ]
then
        echo log=$log
        echo mail=$mail
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
> $log
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
# Backup the / "root" partition
#
echo ""
echo ""
ufsdump 0cfu $NRDEV /dev/rdsk/c0t0d0s0
if [ $? -ne 0 ]
then
        FAILED=y
        subject="BACKUP FAILED: $host $log"
        echo "\n*** root backup FAILED !! ***"
fi
echo ""
#
# Backup the /opt partition
#
echo ""
echo ""
ufsdump 0cfu $NRDEV /dev/rdsk/c0t1d0s0
if [ $? -ne 0 ]
then
        FAILED=y
        subject="BACKUP FAILED: $host $log"
        echo "\n*** /opt backup FAILED !! ***"
fi
echo ""
#
# Backup the /export directory
#
echo ""
echo ""
cd /export
#echo "Subject: Backup status for williams"
#echo "Directories to be backed up from williams:/export:\n\n${FILES}\n\n"
#echo "Start time: `date`\n\n"
tar cvbf 128 $NRDEV $FILES
#ufsdump 0cfu $NRDEV /dev/md/dsk/d52
if [ $? -ne 0 ]
then
        FAILED=y
        subject="BACKUP FAILED: $host $log"
        echo "\n*** /export backup FAILED !! ***"
fi
#
#  Report the end time
#
echo "\n\nEnd time: `date`"
echo ""
echo ""
echo "Backups finished, rewinding tape"
mt -f $RDEV rewind
echo "Backup script finished at `date`"
} >> $log 2>&1
#
# Mail status of backup to users
#
#jd changed by jd 9-oct-2000 -- now produces a number, not a string
#jd loglen=`wc -l $log`
loglen=`wc -l $log | awk '{ print $1 }'`
if [ $loglen -gt 200 ]
then
	( head -100 $log; echo "  .\n  .\n  .\n"; tail -100 $log ) \
	| mailx -s "$subject" $mail
else
	cat $log | mailx -s "$subject" $mail
fi
#
# Eject the tape
#
mt -f $RDEV offline
#
# Mail admin to change tape
#
## jd 4-jan-2000 - temp change, please uncomment
echo $nexttape > $tapefile
## jd echo "\n\n$admin_name\n\nPlease change the tape in the williams server to '$host-$nexttape'.\n\n\nThanks!" | mailx -s "TAPE CHANGE: $host" -c "$mail" $admin
#
# The End!
#

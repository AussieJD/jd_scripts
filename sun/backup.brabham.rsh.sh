#!/bin/ksh
#
# Description   :
#
# This backup script performs a backup of brabham with the
# dump command for the root and tar for the export partition.  
#
# Usage         : backup.brabham.rsh.sh
# Modifications :
#       26-nov-99       j.driscoll     created script to back up brabham to the DLT4000 on williams
#					designed as a manual backup
#
DAY=`date +%a`
DATE=`date +%a," "%d-%h-%Y`
SCRIPT=`basename $0`
LOG=/tmp/${SCRIPT}.log.`date +%d-%h-%Y`
echo $LOG
RDEV="/dev/rmt/0"; export RDEV
NRDEV="/dev/rmt/0n"; export NRDEV
FAILED=n
#
#### start the process of a ufsdump of brabham:/ and a tar of brabham:/export
#
echo " Starting the backup process .... writing to log file...."
( echo ""
echo "Backup script started at `date`"
echo ""
#
################# Backup the brabham:/ "root" partition
#
echo ""
echo ""
echo " Start:\t\t`date +%a-%d-%h`\t`date +%r`"
echo ""
rsh brabham ufsdump 0cfu - /dev/rdsk/c0t0d0s0 | dd obs=64512 of=$NRDEV
 if [ $? -ne 0 ]
then
        FAILED=y
        echo "*** root backup FAILED !! ***"
 fi
#echo ""
echo " End:\t\t`date +%a-%d-%h`\t`date +%r`"
echo ""
#
################# Backup the brabham:/export partition
#
echo ""
echo " Start:\t\t`date +%a-%d-%h`\t`date +%r`"
echo ""
#rsh brabham 'cd /export;tar cvfr - *' | /usr/local/bin/gzip | dd of=$RDEV
rsh brabham 'cd /export;tar cvfr - *' | dd obs=64512 of=$RDEV
 if [ $? -ne 0 ]
then
        FAILED=y
        echo "*** export backup FAILED !! ***"
 fi
echo ""
echo " End:\t\t`date +%a-%d-%h`\t`date +%r`"
#
#
echo "\n\nEnd time: `date`"
echo ""
echo ""
echo "Backups finished, rewinding tape AND EJECTING...."
mt -f $RDEV rewind
mt -f $RDEV offline
echo "Backup script finished at `date`"
) > $LOG 2>&1
#
# Mail status of backup to users
#
(head -150 ${LOG}; echo "  .\n  .\n  .\n"; tail -150 ${LOG}) | mailx -s "$SCRIPT for `uname -n` on `date` jon@adelaide
#
#
# The End!


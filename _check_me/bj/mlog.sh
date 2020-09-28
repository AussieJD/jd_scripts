#!/bin/sh
#
# This script is to be run from cron on the first day of each month,
# it moves the specified mail log file to a new file name, ie. "mlog"
# to "mlog.<month><year>". In addition it also creates a new
# Read_<month><year> file.
#
MAILDIR=$HOME/Mail
MLOG=$MAILDIR/mlog
RLOG=$MAILDIR/Read_`date +%b%y`
MLOG2=$MAILDIR/mlog_history/mlog
MAIL=brodie
MONTH=`date +%m`
YEAR=`date +%y`
#
# If month is January change year back one
#
if [ "$MONTH" -eq "01" ]
then
	YEAR=`expr $YEAR - 1`
fi
case $MONTH in
	01)	FILE=Dec${YEAR};;
	02)	FILE=Jan${YEAR};;
	03)	FILE=Feb${YEAR};;
	04)	FILE=Mar${YEAR};;
	05)	FILE=Apr${YEAR};;
	06)	FILE=May${YEAR};;
	07)	FILE=Jun${YEAR};;
	08)	FILE=Jul${YEAR};;
	09)	FILE=Aug${YEAR};;
	10)	FILE=Sep${YEAR};;
	11)	FILE=Oct${YEAR};;
	12)	FILE=Nov${YEAR};;
esac
MLOG2=$MLOG2.$FILE
mv $MLOG $MLOG2
> $RLOG
#
# Report action to user
#
(
echo "\n\nMail send log file $MLOG moved to $MLOG2..."
echo "\n\nCreated new read log file $RLOG..."
) | mailx -s "Mailbox maintenance (mlog)..." $MAIL
#
# The End!
#

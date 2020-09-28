#!/bin/sh
#
# This script is to be run from cron on the first day of each month, it moves
# the specified Reading files to a new file name, ie. "Reading_Storage"
# to "Reading_Storage.<month><year>".
#
BASEDIR=$HOME/Mail/Reading
RPTLOG=/tmp/`basename $0`.$$
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
	01)	EXT=Q4_CY${YEAR};;
	03)	EXT=Q4_CY${YEAR};;
	04)	EXT=Q1_CY${YEAR};;
	07)	EXT=Q2_CY${YEAR};;
	10)	EXT=Q3_CY${YEAR};;
esac
echo "\n\n" > $RPTLOG
for FILE in Storage Network PC Technical Security SAP SIMS OS Starfire
do
	FILE2=$FILE.$EXT
	cd $BASEDIR
	mv $FILE $FILE2
	echo "Moved $FILE \t\tto $FILE2..." >> $RPTLOG
done
#
# Report action to user
#
cat $RPTLOG | mailx -s "Mailbox maintenance (Reading)..." $MAIL
#
# The End!
#

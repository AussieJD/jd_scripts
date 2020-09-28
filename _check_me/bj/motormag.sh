#!/usr/bin/ksh
#
# This script is to be run from cron on the first day of each month,
# it reminds the paticipant whos turn it is to purchase a motor magazine.
#
BJ=brodie
JT=johnt
RMC=richard.mcdougall@eng
MTH=`date +%m`
#
# Set paramters
#
case $MTH in
	01)	MONTH=January; NAME=Brodie; TO=$BJ; CC="$JT,$RMC";;
	02)	MONTH=February; NAME=John; TO=$JT; CC="$BJ,$RMC";;
	03)	MONTH=March; NAME=Richard; TO=$RMC; CC="$JT,$BJ";;
	04)	MONTH=April; NAME=Brodie; TO=$BJ; CC="$JT,$RMC";;
	05)	MONTH=May; NAME=John; TO=$JT; CC="$BJ,$RMC";;
	06)	MONTH=June; NAME=Richard; TO=$RMC; CC="$JT,$BJ";;
	07)	MONTH=July; NAME=Brodie; TO=$BJ; CC="$JT,$RMC";;
	08)	MONTH=August; NAME=John; TO=$JT; CC="$BJ,$RMC";;
	09)	MONTH=September; NAME=Richard; TO=$RMC; CC="$JT,$BJ";;
	10)	MONTH=October; NAME=Brodie; TO=$BJ; CC="$JT,$RMC";;
	11)	MONTH=November; NAME=John; TO=$JT; CC="$BJ,$RMC";;
	12)	MONTH=December; NAME=Richard; TO=$RMC; CC="$JT,$BJ";;
esac
#
# Send reminder email to users
#
(
echo "\n*** NOTE: THIS IS AN AUTOMATICALLY GENERATED E-MAIL MESSAGE."
echo "\n\n${NAME}\n\nIt is your turn to purchase a motor magazine of your choice"
echo "for the month of ${MONTH} and circulate it to the participants."
echo "\nThankyou."
) | mailx -s "Motor Magazine Reminder..." -c $CC $TO
#
# The End!
#

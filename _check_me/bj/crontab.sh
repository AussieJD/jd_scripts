#!/usr/bin/ksh
#
# This script is to be run from cron on the first day of each month,
# it listed the cron jobs run for this user to a file named "crontab.list"
# in the users home directory.
#
CRONTAB=$HOME/crontab.list
echo "#\n# Output from crontab -l on `date +'%d %b %y'`\n#" > $CRONTAB
crontab -l >> $CRONTAB
#
# The End!
#

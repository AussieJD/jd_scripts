# tar and compress a directory to a specified place
# - designed to be run from CRON
#
BACKUPDIR=/home/staff/jon/Mail		# directory to be backed up
BACKUPSTORE=/u1/backups			# place to store backups
#
DATE=`date +%d.%m.%y`			# a date desriptor for filenames
#
# tar up the specified backup directory and then compress
##########################################################################
#
tar cvf $BACKUPSTORE/mailbak.${DATE}.tar $BACKUPDIR
compress $BACKUPSTORE/mailbak.${DATE}.tar

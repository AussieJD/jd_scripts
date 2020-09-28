# tar and compress a directory to a specified place
# - designed to be run from CRON
#
BACKUPNAME=jon.bin			# place to store backups
BACKUPDIR=/home/staff/jon/bin		# directory to be backed up
BACKUPSTORE=/u1/backups			# place to store backups
#
DATE=`date +%d.%m.%y`			# a date desriptor for filenames
#
# tar up the specified backup directory and then compress
##########################################################################
#

tar cvf $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar $BACKUPDIR
compress $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar

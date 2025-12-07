# tar and compress a directory to a specified place
# - designed to be run from CRON
############################################################################
######  1st backup run ###########

BACKUPNAME=jon.jdnet			# place to store backups
BACKUPDIR=/home/staff/jon/jdnet		# directory to be backed up
BACKUPSTORE=/u1/backups			# place to store backups
#
DATE=`date +%d.%m.%y`			# a date desriptor for filenames
#
# tar up the specified backup directory and then compress
##########
#

tar cvfhr $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar $BACKUPDIR
compress $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar

############################################################################
######  2nd backup run ###########

BACKUPNAME=jon.graphics			# place to store backups
BACKUPDIR=/home/staff/jon/graphics	# directory to be backed up
BACKUPSTORE=/u1/backups			# place to store backups
#
DATE=`date +%d.%m.%y`			# a date desriptor for filenames
#
# tar up the specified backup directory and then compress
#

tar cvfhr $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar $BACKUPDIR
compress $BACKUPSTORE/${BACKUPNAME}.${DATE}.tar

############################################################################
chmod 775 /u1/ba*/*
The End.

# tar and compress a directory to a specified place
# - designed to be run from CRON
#
#BACKUPDIR=/home/staff/jon/Mail		# directory to be backed up
BACKUPSTORE=/u1/backups			# place to store backups
#
DATE=`date +%d.%m.%y`			# a date desriptor for filenames ie.28.05.98
#
# tar up the specified backup directory and then compress
##########################################################################
#

#tar cvf $BACKUPSTORE/mailbak.${DATE}.tar $BACKUPDIR


tar cvf $BACKUPSTORE/contacts.jd.${DATE}.tar /home/staff/jon/jon/contacts.jd
tar cvf $BACKUPSTORE/modloan.jd.${DATE}.tar /home/staff/jon/jon/modloan.jd

compress $BACKUPSTORE/contacts.jd.${DATE}.tar
compress $BACKUPSTORE/modloan.jd.${DATE}.tar
chmod 775 /u1/ba*/*

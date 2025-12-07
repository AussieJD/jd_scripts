#!/bin/sh
#
# Pull Transfer files from APCAP (syd0497) using rsync, and a list of folders
# - usage: requied argument of up or down, that specify which end of the list to start at
#	 	and allowing 2x instances of the script to be run at once

#BASE=/migration1/apcap/data-migration/data		# local folder where data is sync'd to
SOURCEFILE=/migration1/apcap/data-migration/uvh-apcap-data-sizes.out	# list of "items" to sync from $DATA 
BASE=/zones/fs/syd0497/data				# local folder where data is sync'd to
DATA=/data						# remote folder to sync from
SOURCEFILE=/migration1/apcap/data-migration/uvh-apcap-data-sizes.out	# list of "items" to sync from $DATA 
BWL=8000						# rsync bandwidth limit (1000=1MB/s)

cd $BASE

if [ "$1" = "1" -o "$1" = "2" -o "$1" = "3" ] 
 then
	for i in `cat $SOURCEFILE | grep \^$1 | awk '{print $2}'`
	 do
#		echo ""
#		date 
		printf "$1: $i: "
		rsync -a -H -x  --bwlimit=$BWL --delete --stats --numeric-ids root@apcap2:$DATA/$i . 2>/dev/null | egrep '^Number of files transferred'
#		sleep 60
	done 

	
else
	echo "usage: $0 {1|2|3}"
	exit 1	
fi

#
# The End!

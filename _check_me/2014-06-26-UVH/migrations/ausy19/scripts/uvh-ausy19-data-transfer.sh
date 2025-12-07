#!/bin/sh
#
# pull files from target using rsync, an item number, and a server name

REMOTE_RSYNC=/export/home/cz0qk6/rsync-sol8

# list of "items" to sync from $DATA 
SOURCEFILE=/UVH/migrations/ausy19/scripts/uvh-ausy19-data-sizes.out
BWL=90000			# rsync bandwidth limit (1000=1MB/s)
BASE=/migration5/ausy19		# local folder where data is sync'd to

if [ $# != 1 ]
then
	echo "usage: $0 {index}"
	exit 1
fi
cd $BASE || exit 1

DATE=`date +%y%m%d-%H%M`
exec > $BASE/logs/$DATE-ausy19-$1 2>&1

echo "`date` : ausy19 $1 started"
T1=`date +%H%M`
for i in `grep "^$1 ausy19 " $SOURCEFILE |  awk '{print $3}'`
 do
	T2=`date +%H%M`
	echo "----- "
	echo "started: ausy19: $1: $i: (${T2})   "
	/usr/local/bin/rsync -a -H -x --bwlimit=$BWL --delete --stats --numeric-ids --rsync-path=$REMOTE_RSYNC root@ausy19:$i . 
	T3=`date +%H%M` ; E1=`echo "${T3}-${T2}" | bc`
	echo "finished: ausy19: $1: $i: (`date +%H%M`)($E1 mins)"
	echo ""
done
T4=`date +%H%M` ; E2=`echo "${T4}-${T1}" | bc`
echo "`date` : ausy19 $1 finished ($E2 mins total elapsed)"

#
# The End!

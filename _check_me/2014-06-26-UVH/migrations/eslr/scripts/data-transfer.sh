#!/bin/sh
#
# pull files from target using rsync, an item number, and a server name

REMOTE_RSYNC=/export/home/cz0qk6/rsync-sol10

# list of "items" to sync from $DATA
SOURCEFILE=/UVH/migrations/eslr/scripts/data-sizes
BASE=/migration2/eslr/aubwsgipw100/vb01		# local folder where data is sync'd to

if [ $# != 2 ]
then
	echo "usage: $0 {index} {1|2}"
	exit 1
fi
[ _"$2" = _1 ] && VLAN=1904a || VLAN=1906
cd $BASE || exit 1

DATE=`date +%y%m%d-%H%M`
exec > /migration2/eslr/logs/$DATE-kev-$1-$VLAN 2>&1

echo "`date` : $1 started"
T1=`date +%H%M`
for i in `grep "^$1 " $SOURCEFILE | awk '{print $3}'`
 do
	T2=`date +%H%M`
	echo "-----"
	echo "started: $1: $i: (${T2})"
	/usr/local/bin/rsync -a -H -x --delete --inplace --progress --stats --numeric-ids --rsync-path=$REMOTE_RSYNC root@aubwsgipw100-$VLAN:/vb01/$i .
	T3=`date +%H%M` ; E1=`echo "${T3}-${T2}" | bc`
	echo "finished: $1: $i: (`date +%H%M`)($E1 mins)"
	echo ""
done
T4=`date +%H%M` ; E2=`echo "${T4}-${T1}" | bc`
echo "`date` : $1 finished ($E2 mins total elapsed)"

#
# The End!

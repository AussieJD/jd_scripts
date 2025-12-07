#!/bin/sh
#
# pull files from target using rsync, an item number, and a server name

REMOTE_RSYNC=/export/home/cz0qk6/rsync-sol8

# list of "items" to sync from $DATA
SOURCEFILE=/UVH/migrations/vcc/scripts/uvh-vcc-data-sizes.out
BWL=2000			# rsync bandwidth limit (1000=1MB/s)
BASE=/migration5/vcc/outage2	# local folder where data is sync'd to

if [ $# != 2 ]
then
	echo "usage: $0 {index} {server}"
	exit 1
fi
cd $BASE/$2 || exit 1

DATE=`date +%y%m%d-%H%M`
ERR=$BASE/logs/$DATE-$2-$1.err
exec > $BASE/logs/$DATE-$2-$1 2>&1

nmins()
{
	T="$1"

	NMINS_X=`expr "$T" : "\([0-9][0-9]*\)..\$"`
	NMINS_Y=`expr "$T" : ".*\([0-9][0-9]\)\$"`
	[ _"$NMINS_X" = _ -o _"$NMINS_Y" = _ ] && return 1
	echo `expr $NMINS_X \* 60 + $NMINS_Y`
	return 0
}

delt()
{
	DELT_X=`nmins $1`
	[ $? -ne 0 ] && return 1
	DELT_Y=`nmins $2`
	[ $? -ne 0 ] && return 1
	echo `expr $DELT_Y - $DELT_X`
	return 0
}

echo "`date` : $2 $1 started"
T1=`date +%H%M`
for i in `grep "^$1 $2 " $SOURCEFILE | awk '{print $3}'`
 do
	T2=`date +%H%M`
	echo "----- "
	echo "started: $2: $1: $i: (${T2})   "
	/usr/local/bin/rsync -a -H -x --bwlimit=$BWL --delete --inplace --stats --numeric-ids --rsync-path=$REMOTE_RSYNC root@$2:$i . 2> $ERR |
	    egrep -v "^Number of files:|^Total file size:|^Literal data:|^Matched data:|^File list |^Total bytes |^sent |^total size is " | grep .
	egrep -v "^BE ADVISED|^Use of this network|^\$" $ERR
	rm $ERR
	T3=`date +%H%M`
	Z=`delt $T2 $T3`
	[ $? -ne 0 ] && Z=?
	echo "finished: $2: $1: $i: ($T3)($Z mins)"
done
Z=`delt $T1 $T3`
[ $? -ne 0 ] && Z=?
echo "`date` : $2 $1 finished ($Z mins total elapsed)"

#
# The End!

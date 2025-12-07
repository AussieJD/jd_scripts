#!/bin/sh

DIR=/UVH/tmp/ohc
LIST="auszvuvh001 auszvuvh004"

TMP=/tmp/ohcr.$$
trap "rm -f $TMP ; Exit" 0 2 3
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

exec > $TMP

if [ ! -d $DIR ]
then
	echo "$DIR not found"
	Exit 1
fi
X=`df -k $DIR | grep "^/dev/md/"`
[ _"$X" = _ ] && Exit 0
cd $DIR || Exit 1

for i in $LIST
do
	if [ ! -s $i ]
	then
		echo "$i - no report found"
		continue
	fi
	egrep -v " OK | OK\$" $i > ERR
	if [ -s ERR ]
	then
		echo "$i bad:"
		cat ERR
	else
		echo "$i OK"
		rm $i
	fi
done
rm -f ERR
if [ -s $TMP ]
then
    (
	cat <<!
(best if any mail-reader message reformatting is disabled)

!
	cat $TMP
    ) | mailx -r UVHhealthcheck -s "daily health report" root
fi

Exit 0

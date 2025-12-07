#!/bin/sh
# daily crontab report on staged backups from remote servers

BDIR=/UVH/backups	# all staged backups under here
LOG=`date +%y%m%d`	# log filename style used by uvh-stgbup.sh

TMP=/tmp/stagedbu.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

[ _"$1" = _- ] && CRON=true
X=`df -h $BDIR 2> /dev/null | grep "^/dev/md/"`
if [ _"$X" = _ ]
then
	[ _"$CRON" = _ ] && echo "$BDIR not directly mounted here"
	Exit 0
fi
cd $BDIR || Exit 1
for i in *
do
	[ ! -d $i/logs ] && continue
	[ -s $TMP ] && echo "" >> $TMP
	F=$i/logs/$LOG
	if [ -f $F ]
	then
		X=`ls -l $F | sed "s/  */ /g" | cut -d' ' -f8`
		echo "$i (finished at $X)"
		cat $F
	else
		echo $i
		echo " *** no report available ***"
	fi >> $TMP
done
if [ _"$CRON" != _ ]
then
	mailx -r UVHstgbu -s "staged backup report `date +%d/%m/%y`" root < $TMP
else
	cat $TMP
fi
Exit 0

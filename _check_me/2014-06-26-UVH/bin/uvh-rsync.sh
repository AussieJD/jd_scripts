#!/bin/sh
# daily crontab synchronisation of /UVH to /UVHbu
# can be run on multiple hosts - if either filesystem not mounted and invoked
#   with -q will exit silently

# uses rsync (trashes file access times)

TMP=/tmp/uvhbu.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3
DATE=`date +%d-%b-%y`
STATUS=0
HOST=`hostname | cut -f1 -d.`

FROM=/UVH
TO=/UVHbu

RSYNC=/usr/local/bin/rsync
RSYNC_OPTS="-a -H -x --delete --numeric-ids"

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

scale()
{
	N=$1

	if [ $N -ge 10000000000 ]		# 10^10
	then
		N=`expr $N + 500000000`		# 0.5 * 10^9
		N=`expr $N / 1000000000`	# 10^9
		echo "${N}G"
		return
	fi
	if [ $N -ge 1000000000 ]		# 10^9
	then
		N=`expr $N + 50000000`		# 0.5 * 10^8
		N=`expr $N / 100000000`		# 10^8
		echo "`expr $N / 10`.`expr $N % 10`G"
		return
	fi
	if [ $N -ge 10000000 ]			# 10^7
	then
		N=`expr $N + 500000`		# 0.5 * 10^6
		N=`expr $N / 1000000`		# 10^6
		echo "${N}M"
		return
	fi
	if [ $N -ge 1000000 ]			# 10^6
	then
		N=`expr $N + 50000`		# 0.5 * 10^5
		N=`expr $N / 100000`		# 10^5
		echo "`expr $N / 10`.`expr $N % 10`M"
		return
	fi
	if [ $N -ge 10000 ]			# 10^4
	then
		N=`expr $N + 500`		# 0.5 * 10^3
		N=`expr $N / 1000`		# 10^3
		echo "${N}K"
		return
	fi
	if [ $N -ge 1000 ]			# 10^3
	then
		N=`expr $N + 50`		# 0.5 * 10^2
		N=`expr $N / 100`		# 10^2
		echo "`expr $N / 10`.`expr $N % 10`K"
		return
	fi
	echo $N
}

while [ $# -ge 1 ]
do
	case "$1"
	in
	-)	CRON=true ;;
	-v)	VERBOSE=true ;;
	*)	echo "usage: $0 [-][-v]"
		exit 1
		;;
	esac
	shift
done

X=`mount | grep "$FROM "`
if [ _"$X" = _ ]
then
	[ _"$CRON" = _ ] && echo "$FROM not mounted"
	Exit 0
fi
X=`mount | grep "$TO "`
if [ _"$X" = _ ]
then
	[ _"$CRON" = _ ] && echo "$TO not mounted"
	Exit 0
fi

cd $FROM || Exit 1	# avoids extra level in $TO

# dry run to show what will be done
if [ _"$VERBOSE" != _ ]
then
	$RSYNC $RSYNC_OPTS -n -v . $TO |
	    egrep -v "^sending incremental file list|^sent .* bytes  *received .* bytes|^total size is " |
	    grep . > $TMP

	cat > $TMP.m <<!
Subject: UVH backup $HOST $DATE
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=kev_was_here

This is a multi-part message in MIME format.
Since your mail reader does not understand this format,
some or all of this message may not be legible.

--kev_was_here
Content-Type: text/plain

!
fi
cat >> $TMP.m <<!
(best if any mail-reader message reformatting is disabled)

rsync /UVH to /UVHbu on $HOST
!

# actual sync - filter output to reduce noise level for mail summary
$RSYNC $RSYNC_OPTS --inplace --stats . $TO 2>&1 |
    egrep -v "^Number of files:|^Total file size:|^Literal data:|^Matched data:|^File list |^Total bytes |^sent |^total size is " |
    grep . > $TMP.o
X=`wc -l < $TMP.o`
if [ $X -eq 2 ]
then
	X=`grep "Number of files transferred: " $TMP.o | cut -f2 -d:`
	Y=`grep "Total transferred file size: " $TMP.o | cut -f2 -d:`
	if [ _"$X" != _ -a _"$Y" != _ ]
	then
		Z=`expr "$X" : " \([0-9][0-9]*\)\$"`
		[ _"$Z" != _ ] && X=$Z
		Z=`expr "$Y" : " \([0-9][0-9]*\) bytes\$"`
		[ _"$Z" != _ ] && Y=`scale $Z`
		echo "$X files ${Y}b" > $TMP.o
	fi
fi
[ -s $TMP.o ] && cat $TMP.o >> $TMP.m
if [ _"$VERBOSE" != _ ]
then
	echo "" >> $TMP.m
	if [ ! -s $TMP ]
	then
		echo "(nothing changed)" >> $TMP.m
	else
		cat >> $TMP.m <<!
(filenames attached)
--kev_was_here
Content-Type: text/plain; name=messages-extract.txt

!
		cat $TMP >> $TMP.m
		cat >> $TMP.m <<!
--kev_was_here--
!
	fi
	sendmail root < $TMP.m
else
	mailx -s "UVH backup $DATE" root < $TMP.m
fi
rm -f $TMP.m $TMP
Exit 0

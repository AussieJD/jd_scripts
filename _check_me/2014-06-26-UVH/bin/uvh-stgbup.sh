#!/bin/sh
# daily crontab synchronisation of named remote server to its local staging
#   area (currently requires remote root password-less key-exchange access)

# uses rsync (which trashes file access times) in order to provide sensible
#   full and incremental images to Data Protector

USAGE="usage: $0 [-][-v] conf-file"
TAB='	'			# care - tab (don't cut and paste)
BDIR=/UVH/backups		# all staged backups under here
RSYNC=/usr/local/bin/rsync	# change to /bin/echo to debug!

TMP=/tmp/stagedbu.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3
STATUS=0

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

del_noise()
{
	F=$1

	sed -n "1,${MOTD_WC}p" $F > $TMP.tmp
	cmp -s $TMP.motd $TMP.tmp
	[ $? != 0 ] && return
	sed "1,${MOTD_WC}d" $F > $TMP.tmp
	cp $TMP.tmp $F
	rm $TMP.tmp
}

# rsync options:
#   -a		recurse dirs, do specials, keep symlinks+uid/gid+perms+mtime
#   -H		preserve hard links
#   -x		don't cross filesystem boundaries
#   --delete	delete extraneous files on target
#   --numeric-ids
#		keep uid/gid (don't use local mappings of names)
#   -e ssh	use ssh to connect (set up keys)
#   --inplace	update target files directly (do not make temporary copy)
#   -n		show what would be done (do not do it)
#   -v		verbose
#   --stats	file-transfer stats
#
#   can also have --exclude={pattern}
RSYNC_OPTS="-a -H -x --delete --numeric-ids -e ssh"

rs()
{
	FS="$1"

	RFS=$FS
	if [ _"$RFS" = _/ ]
	then
		LDIR=root
	else
		RFS=$RFS/	# trailing / needed for dopey rsync
		LDIR=`echo "$FS" | sed -e "s/^\///" -e "s/\//_/g"`
	fi
	grep -v "^$LDIR\$" $TMP.fs > $TMP.x
	mv $TMP.x $TMP.fs
	LDIR=$BDIR/fs/$LDIR

	# dry run to show what will be done
	if [ _"$VERBOSE" != _ ]
	then
		$RSYNC $RSYNC_OPTS -n -v $RHOST:$RFS $LDIR 2> $TMP.err |
		    egrep -v "^receiving incremental file list|^sent .* bytes  *received .* bytes|^total size is " |
		    grep . > $TMP.dr
		del_noise $TMP.err
		[ -s $TMP.err ] && cat $TMP.err >> $TMP.dr
	fi

	# actual sync - filter output to reduce noise level for summary
	$RSYNC $RSYNC_OPTS --inplace --stats $RHOST:$RFS $LDIR 2> $TMP.err |
	    egrep -v "^Number of files:|^Total file size:|^Literal data:|^Matched data:|^File list |^Total bytes |^sent |^total size is |^skipping non-regular file " |
	    grep . > $TMP
	del_noise $TMP.err
	[ -s $TMP.err ] && cat $TMP.err >> $TMP
	rm $TMP.err

	if [ _"$VERBOSE" != _ ]
	then
		if [ ! -s $TMP.dr ]
		then
			echo "(nothing changed)"
		else
			cat $TMP.dr
		fi
		rm $TMP.dr
		echo ""
	fi
	X=`wc -l < $TMP`
	if [ "$X" -eq 2 ]
	then
		X=`grep "Number of files transferred: " $TMP | cut -f2 -d:`
		Y=`grep "Total transferred file size: " $TMP | cut -f2 -d:`
		if [ _"$X" != _ -a _"$Y" != _ ]
		then
			Z=`expr "$Y" : " \([0-9][0-9]*\) bytes\$"`
			if [ _"$Z" = _ ]
			then
				echo "$FS:$X files$Y"
			else
				echo "$FS:$X files `scale $Z`b"
			fi
			rm $TMP
			return
		fi
	fi
	echo ----------
	echo "$FS"
	cat $TMP
	echo ----------
	rm $TMP
}

while [ $# -gt 0 ]
do
	case "$1"
	in
	-)	CRON=true ;;
	-v)	VERBOSE=true ;;
	*)	if [ _"$SVR" != _ ]
		then
			echo "$USAGE"
			Exit 1
		fi
		SVR="$1"
		;;
	esac
	shift
done
X=`df -h $BDIR 2> /dev/null | grep "^/dev/md/"`
if [ _"$X" = _ ]
then
	[ _"$CRON" = _ ] && echo "$BDIR not directly mounted here"
	Exit 0
fi
if [ _"$SVR" = _ ]
then
	echo "$USAGE"
	Exit 1
fi
if [ ! -d "$BDIR" ]
then
	echo "can't find $BDIR"
	Exit 1
fi
BDIR=$BDIR/$SVR
CONF=$BDIR/conf
if [ ! -r "$CONF" ]
then
	echo "can't read $CONF"
	Exit 1
fi
LOGS=$BDIR/logs
LOG=$LOGS/`date +%y%m%d`
# pre-digest configuration file for ease of subsequent matches
sed -e "s/#.*//" -e "s/[ $TAB][ $TAB]*/ /g" -e "s/ \$//" -e "/^\$/d" "$CONF" > $TMP.conf

RHOST=`grep "^rhost " $TMP.conf | tail -1 | cut -d' ' -f2-`
if [ _"$RHOST" = _ ]
then
	echo "can't find rhost in $CONF"
	Exit 1
fi
RCMD=`grep "^rcmd " $TMP.conf | tail -1 | cut -d' ' -f2-`
if [ _"$RCMD" = _ ]
then
	echo "can't find rcmd in $CONF"
	Exit 1
fi
LIST=`grep "^fs " $TMP.conf | cut -d' ' -f2-`
if [ _"$LIST" = _ ]
then
	echo "can't find fs in $CONF"
	Exit 1
fi
IGNORE=`grep "^ign " $TMP.conf | cut -d' ' -f2-`

RSYNC_OPTS="$RSYNC_OPTS --rsync-path=$RCMD"

ls $BDIR/fs > $TMP.fs
X=`ssh $RHOST "uname -s" 2> /dev/null`
if [ _"$X" = _SunOS ]
then
	ssh $RHOST "df -k -F ufs" 2> /dev/null > $TMP.x
	ssh $RHOST "df -k -F vxfs" 2> /dev/null >> $TMP.x
elif [ _"$X" = _Linux ]
then
	ssh $RHOST "df -k -t ext3 -t ext4" 2> /dev/null > $TMP.x
else
	ssh $RHOST "df -k" 2> /dev/null > $TMP.x
fi
grep " " $TMP.x | grep -v "^Filesystem" | sed "s/.* //" > $TMP.df
rm $TMP.x
scp $RHOST:/etc/motd $TMP.motd 2> /dev/null
MOTD_WC=`wc -l < $TMP.motd`
MOTD_WC=`echo $MOTD_WC`	# strip leading spaces
for i in $IGNORE
do
	grep -v "^$i\$" $TMP.df > $TMP.x
	mv $TMP.x $TMP.df
done
if [ -s $LOG ]
then
	echo ""
	echo ==========
	echo ""
fi >> $LOG
for i in $LIST
do
	rs $i
	grep -v "^$i\$" $TMP.df > $TMP.x
	mv $TMP.x $TMP.df
done >> $LOG

if [ -s $TMP.df ]
then
	echo ==========
	echo "following filesystems not backed up:"
	cat $TMP.df
fi >> $LOG
rm $TMP.df

if [ -s $TMP.fs ]
then
	echo ==========
	echo "following filesystems no longer being backed up:"
	cat $TMP.fs
fi >> $LOG

[ _"$CRON" = _ ] && cat $LOG
cd $LOGS || Exit 1
find * -type f -mtime +30 -exec rm {} \;
Exit 0

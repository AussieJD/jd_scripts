#!/bin/sh

# run a ufsdump on a UVH server to a special ssh-access dummy user "uvhbup"
#    on auszvuvh001 using key-exchange from remote root users

# may be run from crontab

TMP=/tmp/bu.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

REMOTE=uvhbup@auszvuvh001
SERVER=`uname -n`
DATE=`date +%Y-%m-%d_%H-%M`	# better not run twice in same minute!
UFSDUMP_EXTENSION=ufsdump
UFSDUMP_LOG_EXTENSION=ufslog
MAXBACKUPS=4
FILESYSTEMS_TO_DUMP=filesystems-to-dump.list

TAB='	'	# care - tab
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

if [ $# != 0 ]
then
	CRON=true
	exec > $TMP.m 2>&1
fi

BACKUP_DIR=/UVH/backups/$SERVER
ssh $REMOTE "mkdir $BACKUP_DIR/backup-$DATE" || Exit 1

# read filesystems to back up from list
cp /dev/null $TMP.mp
cp /dev/null $TMP.no
ssh $REMOTE "cat $BACKUP_DIR/$FILESYSTEMS_TO_DUMP" | grep -v "^#" | grep . |
    sed -e "s/[ $TAB][ $TAB]*/ /g" -e "s/ \$//" | while read LINE
do
	LABEL=`expr "$LINE" : "\(.*\) "`
	if [ _"$LABEL" = _ ]
	then
		DIRECTORY=`expr "$LINE" : " *\(.*\)"`
	else
		DIRECTORY=`expr "$LINE" : ".* \(.*\)"`
	fi

	if [ _"$LABEL" = _ ]
	then
		echo "$DIRECTORY" >> $TMP.no
		continue
	fi
	X=`expr "$LABEL" : ".*\(/\)"`
	if [ _"$X" != _ ]
	then
		echo "$LINE: filesystem label may not contain / - ignored"
		continue
	fi
	if [ _`echo "$DIRECTORY" | cut -c1` != _/ ]
	then
		echo "$LINE: directory must start with / - line ignored"
		continue
	fi
	if [ ! -d $DIRECTORY ]
	then
		echo "$DIRECTORY does not exit - ignored"
		continue
	fi
	[ -s $TMP.mp ] && echo ""
	echo "start `date '+%d/%m/%y %H:%M:%S'` $LABEL ($DIRECTORY)"
	OUTPUT_STEM=$BACKUP_DIR/backup-$DATE/$LABEL-$SERVER-$DATE
	ufsdump 0uf - $DIRECTORY 2> $TMP |
	    ssh $REMOTE "cat > $OUTPUT_STEM.$UFSDUMP_EXTENSION"
	cat $TMP | ssh $REMOTE "cat > $OUTPUT_STEM.$UFSDUMP_LOG_EXTENSION"
	X="^Date of .* level 0 "
	X="$X|^Dumping /dev/"
	X="$X| \(Pass "
	X="$X|^Writing .* Kilobyte records"
	X="$X|^Estimated "
	X="$X|^DUMP IS DONE"
	X="$X|Level 0 dump on "
	sed "s/  *DUMP: //" $TMP | egrep -v "$X" |
	    sed "s/.* blocks (\(.*\)) on [0-9]* volume.* at .* KB.*/\1/"
	echo "end   `date '+%d/%m/%y %H:%M:%S'`"
	echo "$DIRECTORY" >> $TMP.mp
done

for i in `ssh $REMOTE "ls -dt $BACKUP_DIR/backup-*"`
do
	if [ $MAXBACKUPS -gt 0 ]
	then
		MAXBACKUPS=`expr "$MAXBACKUPS" - 1`
		continue
	fi
	CMD="rm -r $i"
	echo ""
	echo $CMD
	ssh $REMOTE "$CMD"
done

sort -u $TMP.mp $TMP.no -o $TMP.mp
rm $TMP.no
mount -v | grep " type ufs " | sed "s/[^ ]* on \([^ ]*\)/\1/" | cut -f1 -d' ' |
    sort > $TMP.mo
comm -23 $TMP.mo $TMP.mp > $TMP
if [ -s $TMP ]
then
	echo ""
	echo "following UFS mountpoints not backed up:"
	cat $TMP
fi

if [ _"$CRON" != _ ]
then
    (
	cat <<!
(best if any mail-reader message reformatting is disabled)

ufsdumps to $REMOTE
$BACKUP_DIR/backup-$DATE

!
	cat $TMP.m
    ) | mailx -r UVHsysbu -s "`hostname` backup" root
fi

Exit 0

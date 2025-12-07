#!/bin/sh

# interrogate Data Protector Cell Manager for results
#   (best if run after that night's backups are known to have completed)
# runs as special user uvhbup (known to DP); if run as root becomes uvhbup
# optional - arg means run from crontab (mail report to root)
# may supply sessionID for report on that session only

# there are presently two cycles - inc kept for 30 days, and full kept for
#   37 days (fulls may also be retained on tapes for an extra 180 days)

# NOTE: queue names may change without warning - if they appear dormant, check
#   with BUR team for new name


UVHBUP=uvhbup
UVH="auszvuvh00[0-9]"
OMNIDB=/opt/omni/bin/omnidb
DIR=/UVH/tmp/dp

TMP=/tmp/dp.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3
TAB='	'	# care - tab!
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

chk_server()
{
	SERVER=`echo $SERVER | cut -f1 -d.`	# strip domain
	[ _"$SERVER" = _ ] && return 1
	X=`expr "$SERVER" : "\($UVH\)\$"`	# check for unrelated servers
	[ _"$X" = _ ] && SERVER=
	return 0
}

chk_fs()
{
	[ _"$FS" = _ ] && return 1
	# FS / is special case as expr below will give syntax error
	[ _"$FS" = _/ ] && return 0
	X=`expr "$FS" : ".*/\(platform\)/.*libc"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	X=`expr "$FS" : ".*/\(svc/volatile\)\$"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	X=`expr "$FS" : ".*\(/var/run\)\$"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	X=`expr "$FS" : ".*\(/dev\)\$"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	X=`expr "$FS" : ".*\(/\.SUNWnative/\)"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	X=`expr "$FS" : ".*\(/root/dev/ksyms\)\$"`
	if [ _"$X" != _ ]
	then
		FS=
		return 0
	fi
	return 0
}

chk_date()
{
	D="$1"

	# date is of the form dow mon dd hh:mm:ss yyyy
	X=`expr "$D" : "... \(...\) "`		# mon
	D=`expr "$D" : "... ... \(.*\)"`
	Y=`expr "$D" : "\([ 0-9][0-9]\) "`	# dd
	D=`expr "$D" : ".. \(.*\)"`
	Z=`expr "$D" : "\([0-9][0-9]:[0-9][0-9]\):[0-9][0-9] 20[0-9][0-9]\$"`
	[ _"$X" = _ -o _"$Y" = _ -o _"$Z" = _ ] && return 1
	case "$X"
	in
	Jan)	X=01 ;;
	Feb)	X=02 ;;
	Mar)	X=03 ;;
	Apr)	X=04 ;;
	May)	X=05 ;;
	Jun)	X=06 ;;
	Jul)	X=07 ;;
	Aug)	X=08 ;;
	Sep)	X=09 ;;
	Oct)	X=10 ;;
	Nov)	X=11 ;;
	Dec)	X=12 ;;
	*)	return 1 ;;
	esac
	[ _"$Y/$X" != _"$DATE" ] && return 2
	HHMM="$Z"
	return 0
}

chk_size()
{
	SIZE="$1"

	X=`expr "$SIZE" : "\([0-9][0-9]*\) "`
	Y=`expr "$SIZE" : "[0-9]* \([GMK]\)B\$"`
	[ _"$X" = _ -o _"$Y" = _ ] && return 1
	while [ $X -ge 10000 ]
	do
		# below rounding will give wrong result for limited cases
		# e.g. 9499499 would become 10M (should be 9M)
		X=`expr $X + 500`
		X=`expr $X / 1000`
		case "$Y"
		in
		K)	Y=M ;;
		M)	Y=G ;;
		G)	Y=T ;;
		T)	Y=P ;;
		*)	return 1 ;;
		esac
	done
	Z=`expr "$X" : ".*"`
	while [ $Z -lt 6 ]
	do
		Z=`expr $Z + 1`
		X=" $X"
	done
	SIZE="$X$Y"
	return 0
}

out()
{
	if [ _"$SERVER" != _ -a _"$SKIP" = _ ]
	then
		if [ _"$SIZE" = _ ]
		then
			echo "server $SERVER fs $FS: missing size"
		elif [ _"$STARTHHMM" = _ ]
		then
			echo "server $SERVER fs $FS: missing start time"
		elif [ _"$ENDHHMM" = _ ]
		then
			echo "server $SERVER fs $FS: missing end time"
		elif [ _"$TYPE" = _ ]
		then
			echo "server $SERVER fs $FS: missing type"
		elif [ _"$PROT" = _ ]
		then
			echo "server $SERVER fs $FS: missing protection"
		elif [ _"$CATA" = _ ]
		then
			echo "server $SERVER fs $FS: missing catalog retention"
		else
			[ _"$PROT" != _"$CATA" ] &&
			    echo "server $SERVER fs $FS: protection $PROT != catalog retention $CATA"
			echo "$SERVER $STARTHHMM $ENDHHMM $SIZE $TYPE $CATA $FS" >> $TMP.o
		fi
	fi
	SERVER=
	FS=
	STARTHHMM=
	ENDHHMM=
	SIZE=
	TYPE=
	PROT=
	CATA=
	SKIP=
}

examine()
{
	LABEL=`expr "$LINE" : "\([^:]*\)"`
	VALUE=`expr "$LINE" : "[^:]*:\(.*\)"`
	if [ _"$LABEL" = _ ]
	then
		echo "missing label <$LINE>"
		return
	fi
	if [ _"$LABEL" = _"Object name" ]
	then
		# out() outputs item being accumulated to $TMP.o, errors to
		# stdout, and prepares for next item
		out
		[ _"$VALUE" = _ ] && return	# end of input
		# discard rubbish in quotes (truncated if too long)
		VALUE=`expr "$VALUE" : "\([^']*\)'"`
		X=`expr "$VALUE" : "\(.*\) \$"`
		[ _"$X" != _ ] && VALUE="$X"
		if [ _"$VALUE" = _ ]
		then
			echo "bad Object name <$LINE>"
			SKIP=true
			return
		fi
		SERVER=`expr "$VALUE" : "\([^:]*\)"`
		chk_server
		if [ $? -ne 0 ]
		then
			echo "no server name found in <$LINE>"
			SKIP=true
			return
		fi
		[ _"$SERVER" = _ ] && SKIP=true
		FS=`expr "$VALUE" : "[^:]*:\(.*\)"`
		chk_fs
		if [ $? -ne 0 ]
		then
			echo "no fs found in <$LINE>"
			SKIP=true
			return
		fi
		[ _"$FS" = _ ] && SKIP=true
		return
	fi
	[ _"$SKIP" != _ ] && return
	if [ _"$VALUE" = _ ]
	then
		echo "missing value <$LINE>"
		return
	fi
	if [ _"$LABEL" = _"Object status" ]
	then
		if [ _"$VALUE" != _Completed ]
		then
			echo "server $SERVER fs $FS: status $VALUE"
			SKIP=true
		fi
		return
	fi
	if [ _"$LABEL" = _"Started" ]
	then
		chk_date "$VALUE"
		RET=$?
		if [ $RET -ne 0 ]
		then
			if [ $RET -eq 1 ]
			then
				echo "server $SERVER fs $FS: bad start date"
				SKIP=true
				return
			fi
			echo "server $SERVER fs $FS: start date not $DATE"
		fi
		STARTHHMM="$HHMM"
		return
	fi
	if [ _"$LABEL" = _"Finished" ]
	then
		chk_date "$VALUE"
		RET=$?
		if [ $RET -ne 0 ]
		then
			if [ $RET -eq 1 ]
			then
				echo "server $SERVER fs $FS: bad end date"
				SKIP=true
				return
			fi
			echo "server $SERVER fs $FS: end date not $DATE"
		fi
		ENDHHMM="$HHMM"
		return
	fi
	if [ _"$LABEL" = _"Object size" ]
	then
		chk_size "$VALUE"
		if [ $? -ne 0 ]
		then
			echo "server $SERVER fs $FS: bad size $VALUE"
			SKIP=true
		fi
		return
	fi
	if [ _"$LABEL" = _"Backup type" ]
	then
		if [ _"$VALUE" = _Incremental ]
		then
			TYPE="inc "
		elif [ _"$VALUE" = _Full ]
		then
			TYPE="full"
		else
			TYPE=" ?? "
		fi
		echo "$TYPE" >> $TMP.type
		return
	fi
	if [ _"$LABEL" = _"Number of errors" ]
	then
		[ _"$VALUE" != _0 ] && echo "server $SERVER fs $FS: errors $VALUE"
		return
	fi
	if [ _"$LABEL" = _"Protection" ]
	then
		# line may end in " (Expired)"
		X=`expr "$VALUE" : ".* \([0-9][0-9]*\) days"`
		if [ _"$X" = _ ]
		then
			echo "server $SERVER fs $FS: bad Protection $VALUE"
			SKIP=true
		else
			PROT="$X"
		fi
		return
	fi
	if [ _"$LABEL" = _"Catalog retention" ]
	then
		# line may end in " (Expired)"
		X=`expr "$VALUE" : ".* \([0-9][0-9]*\) days"`
		if [ _"$X" = _ ]
		then
			echo "server $SERVER fs $FS: bad Catalog $VALUE"
			SKIP=true
		else
			CATA="$X"
		fi
		return
	fi
	return
}

do_session()
{
	X=`expr "$SESSION" : "..../\(..\)/"`		# mm
	DATE=`expr "$SESSION" : "..../../\(..\)"`/$X	# dd/mm
	$OMNIDB -session $SESSION -detail |
	    sed -e "s/[ $TAB][ $TAB]*/ /g" -e "s/ : /:/g" |
	    sed -e "s/^ //" -e "s/ \$//" -e "/^\$/d" > $TMP
	[ ! -s $TMP ] && return 1
	echo "Object name:" >> $TMP	# mark EOF
	SERVER=
	SKIP=
	cp /dev/null $TMP.type
	while read LINE
	do
		examine >> $TMP.e
	done < $TMP
	echo "$SESSION"
	rm $TMP
	X=`grep "full" $TMP.type | wc -l`
	X=`echo $X`	# lose leading blanks
	Y=`grep "inc" $TMP.type | wc -l`
	Y=`echo $Y`	# lose leading blanks
	Z=`wc -l < $TMP.type`
	Z=`expr $Z - $X`
	Z=`expr $Z - $Y`
	Z=`echo $Z`	# lose leading blanks
	[ $Z -ne 0 ] && echo "$Z backup type unknown" >> $TMP.e
	[ $X -ne 0 -a $Y -ne 0 ] &&
	    echo "$X full $Y inc" >> $TMP.e
	if [ -s $TMP.e ]
	then
		echo \----------
		echo "exceptions:"
		cat $TMP.e
		rm $TMP.e
		echo \----------
	fi
	[ -s $TMP.o ] && sort -k 1,1 -k 7,7 $TMP.o
	rm -f $TMP.o
	return 0
}

processDL()
{
	echo "Datalist $DL"
	# Datalist may exist prior to first backup that uses it - so below
	# may generate error noise (discarded)
	$OMNIDB -session -Datalist $DL 2> /dev/null |
	    sed "1,/^====/d" | cut -f1 -d' ' | sort | while read SESSION
	do
		if [ _"$SESSION" = _ ]
		then
			echo "Datalist $DL missing session ID"
			continue
		fi
		X=`expr "$SESSION" : "\(20[0-9][0-9]/[0-9][0-9]/[0-9][0-9]-[0-9][0-9]*\)\$"`
		if [ _"$X" != _"$SESSION" ]
		then
			echo "Datalist $DL sessionID <$SESSION> unrecognised - ignored"
			continue
		fi
		X=`echo $X | tr / -`	# change / to - for local filename
		echo $X >> $TMP.ok
		FN=$DIR/$X
		[ -s $FN ] && continue
		do_session > $FN
		RET=$?
		cat $FN
		[ $RET -ne 0 ] && rm $FN
	done
}

X=`id | cut -f1 -d')' | cut -f2 -d'('`
if [ _"$X" = _root ]
then
	X=`echo "$0" | cut -c1`
	if [ _"$X" != _/ ]
	then
		X=`pwd`/$0
	else
		X=$0
	fi
	exec su - $UVHBUP -c "sh $X $@"
	Exit 1
fi
if [ _"$X" != _$UVHBUP ]
then
	echo "must run $0 as user $UVHBUP"
	Exit 1
fi

if [ _"$1" = _- ]
then
	CRON=true
	shift
fi

if [ _"$1" != _ ]
then
	SESSION="$1"
	do_session
else
	# look for likely-sounding queue names
	for DL in `$OMNIDB -rpt | grep UN | grep LST | sort -u`
	do
		[ -f $TMP.m ] && echo "" >> $TMP.m
		processDL >> $TMP.m
		if [ _"$CRON" = _ ]
		then
			cat $TMP.m
			cp /dev/null $TMP.m
		fi
	done
	if [ -s $TMP.ok ]
	then
		sort $TMP.ok -o $TMP.ok
		ls $DIR > $TMP.ls
		comm -23 $TMP.ls $TMP.ok > $TMP
		if [ -s $TMP ]
		then
			# remove sessions no longer known to DP
			for i in `cat $TMP` ; do rm $DIR/$i ; done
		fi
	fi
	if [ _"$CRON" != _ ]
	then
	    (
		cat <<!
(best if any mail-reader message reformatting is disabled)

!
		cat $TMP.m
	    ) | mailx -r "UVHdp" -s "DP report" root
	fi
	rm $TMP.m
fi
Exit 0

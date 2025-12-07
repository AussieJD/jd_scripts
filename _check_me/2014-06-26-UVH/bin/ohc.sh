#!/bin/sh

# operational health check
#   simple parts should be run hourly

# should also check:
#  prtdiag [-v] environmental status (platform-dependent)
#  broken mirrors or other disk issues (VxVM/ZFS)
#  critical processes running/responding
#  for each interface - known to /etc/networks, mask and broadcast correct
#	UP if {hostname}.{if} exists (look for addif too)
#  hosts.allow should not allow telnet or ftp
#  no /etc/hosts.equiv
#  NIS should not be enabled (SunOS)
#  root PATH not to allow current dir (su - to check?)
#
#  nothing in any lost+found; lost+found only at top of mounted filesystems
#  no core files (naming standards can vary) including old system dumps
#  device files not under /dev or /devices; mode and ownership
#  setuid/setgid files
#  old files in /var/spool (e.g. mqueue, clientmqueue) /var/preserve /var/crash
#    /tmp /usr/tmp /var/tmp (should catch on reboot when cleaned out)
#  user homedirs safe mode owned by user and under /export/home or /home; no
#    user files anywhere else (check large/old mail files)
#  any user .rhosts .shosts .netrc
#  any mail to be owned by correct uid/gid; mode; size; sensible first line;
#    exists yet .forward; no mail for system accounts
#  null passwords; unused accounts; duplicate uids
#  application account must not be loginable; all other accounts EXCEPT root to
#    set /etc/shadow for password expiry and minimum time between changes
#  any unowned or world-writable files/dirs or names with funny characters
#  passwd/group should be sorted by uid/gid (for convenience); shadow order
#    should be same as passwd
#  try to guess easy passwords
#  scrape log files; size (even though rotating)? how check rotating?
#
#  search across servers for
#    same group name different GID
#    same GID different group name
#    same user name different UID
#    same UID different user name
#    same user name different GID
#
#  diff following reports for any changes
#    disk report
#    network report
#    changes to installed packages (pkginfo -l/showrev -a, rpm -qail)

TMP=/tmp/ohc.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

TAB='	'	# care - tab!
STATUS=0

LOCAL=/etc/rc3.d/S99uvh	# run this local script when finished here

EXCEPT="	# exceptions
#test	server		args...
df	auszvuvh004	/zones/aubwsacc003		80	85
df	auszvuvh004	/zones/aubwsacc005		80	85
df	auszvuvh004	/zones/aubwsacc006		85	90
df	auszvuvh004	/zones/fs/aubwsacc006/export-home 80	85
df	auszvuvh004	/zones/fs/aubwsacc006/appams1_orabackup 80 85
df	auszvuvh004	/zones/aubwsacc017		80	85
df	auszvuvh004	/zones/fs/aubwsacc017/cust	85	90
df	auszvuvh004	/zones/syd0497			85	90
df	auszvuvh004	/zones/fs/syd0497/data		80	85
"

QUIET=
VERBOSE=

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

if [ $# = 1 ]
then
	case "$1"
	in
	-q)	QUIET=true ; shift ;;
	-v)	VERBOSE=true ; shift ;;
	esac
fi
if [ $# != 0 ]
then
	echo "Usage: $0 [-q][-v]"
	Exit 1
fi

ohc_df()
{
	DFLT_LO=75
	DFLT_HI=85
	NONE_FOUND="no local mounted filesystems to check"

	# try to limit attention to local filesytems only
	if [ "$OS_VERSION" = SunOS ]
	then
		df -kl | egrep -v "^ctfs |^/dev |^/devices |^/dev/ksyms |^fd |^mnttab |^objfs |^/platform |^/platform/|^proc |^swap |^/.SUNWnative/" > $TMP
		mount | grep " on .* read only" |
		    sed -e "s/.* on \(.*\) read only.*/\1/" > $TMP.x
		while read LINE
		do
			grep -v "^$LINE " $TMP > $TMP.y && mv $TMP.y $TMP
		done < $TMP.x
		rm $TMP.x
	else	# Linux
		df -k -l | egrep -v "^tmpfs " > $TMP
	fi
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "freespace check"
		if [ -s $TMP ]
		then
			cat $TMP
		else
			echo "$NONE_FOUND"
		fi
	fi
	TITLE=`head -1 $TMP`
	$TAIL +2 $TMP > $TMP.x
	rm -f $TMP $TMP.y
	while read LINE
	do
		FS=`expr "$LINE" : ".* \(.*\)"`
		LO=$DFLT_LO
		HI=$DFLT_HI
		X=`echo "$EXCEPT" | grep "^df $NAME $FS " | tail -1`
		if [ _"$X" != _ ]
		then
			X=`expr "$X" : ".* \([0-9][0-9]* [0-9][0-9]*\)"`
			if [ _"$X" = _ ]
			then
				echo "malformed line for \"df $NAME\" - using defaults"
			else
				LO=`expr "$X" : "\(.*\) .*"`
				HI=`expr "$X" : ".* \(.*\)"`
			fi
		fi
		X=`expr "$LINE" : ".* \([0-9]*\)% .*"`
		if [ _"$X" != _ -a "$X" -lt $LO ]
		then
			echo "" >> $TMP	# one per green fs; counted below
			continue
		fi
		if [ _"$X" = _ -o "$X" -gt $HI ]
		then
			echo "$LINE    *****"	# red fs
		else
			echo "$LINE"	# yellow fs
		fi >> $TMP.y
	done < $TMP.x
	if [ ! -s $TMP.y ]	# no yellow or red fs
	then
		if [ _"$QUIET" = _ ]
		then
			[ -s $TMP.x ] && echo "disks OK" || echo "$NONE_FOUND"
		fi
		return 0
	fi
	echo ""
	echo "$TITLE"
	cat $TMP.y
	[ _"$QUIET" != _ ] && return 1
	if [ -s $TMP ]
	then
		X=`wc -l < $TMP`
		X=`echo $X`	# strip leading blanks
		if [ $X != 0 ]
		then
			echo "($X filesystems OK)"
		fi
	fi
	return 1
}

ohc_dfi()
{
	LO=70
	HI=80
	NONE_FOUND="no relevant mounted fs types for inode checking"

	if [ "$OS_VERSION" = SunOS ]
	then
		df -F ufs -o i
	else	# Linux
		df -i -t ext2 -t ext3 -t ext4
	fi > $TMP
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "free inodes check"
		if [ -s $TMP ]
		then
			cat $TMP
		else
			echo "$NONE_FOUND"
		fi
	fi
	TITLE=`head -1 $TMP`
	$TAIL +2 $TMP > $TMP.x
	rm -f $TMP $TMP.y
	while read LINE
	do
		X=`expr "$LINE" : ".* \([0-9]*\)% .*"`
		if [ _"$X" != _ -a "$X" -lt $LO ]
		then
			echo "" >> $TMP	# one per green fs; counted below
			continue
		fi
		if [ _"$X" = _ -o "$X" -gt $HI ]
		then
			echo "$LINE    *****"	# red fs
		else
			echo "$LINE"	# yellow fs
		fi >> $TMP.y
	done < $TMP.x
	if [ ! -s $TMP.y ]	# no yellow or red fs
	then
		if [ _"$QUIET" = _ ]
		then
			[ -s $TMP.x ] && echo "inodes OK" || echo "$NONE_FOUND"
		fi
		return 0
	fi
	echo ""
	echo "$TITLE"
	cat $TMP.y
	[ _"$QUIET" != _ ] && return 1
	if [ -s $TMP ]
	then
		X=`wc -l < $TMP`
		X=`echo $X`	# strip leading blanks
		if [ $X != 0 ]
		then
			echo "($X filesystems OK)"
		fi
	fi
	return 1
}

ohc_swap()
{
	LO=70
	HI=80
	NO_SWAP="no swap devices"

	if [ "$OS_VERSION" = SunOS ]
	then
		swap -l > $TMP
	else	# Linux
		cp /proc/swaps $TMP
	fi
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "swap space check"
		if [ -s $TMP ]
		then
			cat $TMP
		else
			echo "$NO_SWAP"
		fi
	fi
	if [ ! -s $TMP ]
	then
		echo "swaps missing *****"
		return 1
	fi
	TITLE=`head -1 $TMP`
	$TAIL +2 $TMP > $TMP.x
	rm -f $TMP $TMP.y
	while read LINE
	do
		if [ "$OS_VERSION" = SunOS ]
		then
			X=`expr "$LINE" : "[^ ]* *[^ ]* *[0-9]* *\([0-9]*\) *.*"`
			Y=`expr "$LINE" : "[^ ]* *[^ ]* *[0-9]* *[0-9]* *\([0-9]*\)"`
			# X=size, Y=free
			if [ _"$X" = _ -o _"$Y" = _ ]
			then
				X=100	# pretend it's full
			else
				Y=`expr $X - $Y`
				X=`expr $Y \* 100 / $X`	# %full
			fi
		else	# Linux
			X=`expr "$LINE" : "[^ $TAB]*[ $TAB]*[^ $TAB]*[ $TAB]*\([0-9]*\)[ $TAB]*"`
			Y=`expr "$LINE" : "[^ $TAB]*[ $TAB]*[^ $TAB]*[ $TAB]*[0-9]*[ $TAB]*\([0-9]*\)[ $TAB]*"`
			# X=size, Y=used
			if [ _"$X" = _ -o _"$Y" = _ ]
			then
				X=100	# pretend it's full
			else
				X=`expr $Y \* 100 / $X`	# %full
			fi
		fi
		if [ "$X" -lt $LO ]
		then
			echo "" >> $TMP	# one per green swap; counted below
			continue
		fi
		if [ "$X" -gt $HI ]
		then
			echo "$LINE    *****"	# red swap
		else
			echo "$LINE"	# yellow swap
		fi >> $TMP.y
	done < $TMP.x
	if [ ! -s $TMP.y ]	# no yellow or red swap
	then
		if [ _"$QUIET" = _ ]
		then
			[ -s $TMP.x ] && echo "swaps OK" || echo "$NO_SWAP"
		fi
		return 0
	fi
	echo ""
	echo "$TITLE"
	cat $TMP.y
	[ _"$QUIET" != _ ] && return 1
	if [ -s $TMP ]
	then
		X=`wc -l < $TMP`
		X=`echo $X`	# strip leading blanks
		if [ $X != 0 ]
		then
			echo "($X swap partitions OK)"
		fi
	fi
	return 1
}

ohc_swapx()
{
	NO_OUTPUT="no output from swap -s"
	UNEXP="unexpected output from swap -s"
	swap -s > $TMP
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "swap -s check"
		[ -s $TMP ] && cat $TMP
	fi
	X=`wc -l < $TMP`
	if [ $X -ne 1 ]
	then
		if [ -s $TMP ]
		then
			echo "$UNEXP"
		else
			echo "$NO_OUTPUT"
		fi
		return 1
	fi
	LINE=`cat $TMP`
	X=`expr "$LINE" : "total: .* \([0-9]*\)k used"`
	Y=`expr "$LINE" : "total: .* \([0-9]*\)k avail"`
	if [ _"$X" = _ -o _"$Y" = _ ]
	then
		echo "$UNEXP"
		return 1
	fi
	Y=`expr $X + $Y`
	X=`expr $X \* 100 / $Y`
	if [ "$X" -lt $LO ]
	then
		[ _"$QUIET" = _ ] && echo "swap -s OK"
		return 0
	fi
	if [ "$X" -gt $HI ]
	then
		echo "total swap usage $X%    *****"
	else
		echo "total swap usage $X%"
	fi
	return 1
}

ohc_svm()
{
	rm -f $TMP.e
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "SVM check"
	fi
	metadb 2>&1 > $TMP
	X=`grep "no existing database" $TMP`
	if [ _"$X" != _ ]
	then
		[ _"$QUIET" = _ ] && echo "SVM not active"
		return 0
	fi
	metaset 2> /dev/null | grep Set |
	    sed -e "s/.* \([^ ]*\),.*/metadb -s \"\1\"/" > $TMP.s
	[ -s $TMP.s ] && sh $TMP.s >> $TMP 2> /dev/null
	rm $TMP.s
	grep . $TMP | grep -v flags | while read LINE
	do
		# extract flags-firstblk-blkcount
		X=`expr "$LINE" : "[ $TAB]*\(.*[^ $TAB]\)[ $TAB][ $TAB]*"`
		# discard blkcount
		X=`expr "$X" : "\(.*[^ $TAB]\)[ $TAB][ $TAB]*[0-9][0-9]*\$"`
		# discard firstblk
		X=`expr "$X" : "\(.*[^ $TAB]\)[ $TAB][ $TAB]*[0-9][0-9]*\$"`
		# remove whitespace
		X=`echo "$X" | sed -e "s/[ $TAB]//g"`
		# extract device name
		Y=`expr "$LINE" : ".*[ $TAB]\(.*\)"`
		# discard /dev/dsk/
		Y=`expr "$Y" : "/dev/dsk/\(.*\)"`
		[ _"$VERBOSE" != _ ] && echo "$X $Y"
		# any upper-case flags are bad
		X=`expr "$X" : ".*\([A-Z]\)"`
		if [ _"$X" != _ ]
		then
			echo "$Y metadb err" >> $TMP.e
		fi
	done
	# remove normal soft-partition, mirror, and slice lines from metastat
	# output and see if anything is left
	metastat -c 2>&1 |
	    sed -e "/d[0-9][0-9]*  *p  *[0-9][0-9.]*.B d[0-9][0-9]*\$/d" |
	    sed -e "/ *d[0-9][0-9]*  *m  *[0-9][0-9.]*.B d[0-9][0-9]* d[0-9][0-9]*\$/d" |
	    sed -e "/ *d[0-9][0-9]*  *s  *[0-9][0-9.]*.B .dev.dsk.c[^ ]*s[[0-7]\$/d" > $TMP
	if [ -s $TMP ]
	then
		echo "unexpected metastat output" >> $TMP.e
		[ _"$QUIET" = _ ] && cat $TMP >> $TMP.e
	fi
	if [ -s $TMP.e ]
	then
		cat $TMP.e
		rm $TMP.e
		return 1
	fi
	[ _"$QUIET" = _ ] && echo "SVM OK"
	return 0
}

ohc_ntp()
{
	LO=5
	HI=9

	if [ "$OS_VERSION" = SunOS ]
	then
		X=/etc/inet/ntp.conf
	else	# Linux
		X=`chkconfig --list ntpd | grep ":on"`
		[ _"$X" != _ ] && X=/etc/ntp.conf
	fi
	if [ _"$X" != _ -a -s "$X" ]
	then
		Y=`grep "^server " $X | wc -l`
		ntpq -p | grep -v "^.LOCAL" > $TMP
	else
		Y=
	fi
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "ntp check"
		if [ _"$Y" = _ ]
		then
			if [ _"$X" = _ ]
			then
				echo "ntp service not enabled"
			else
				echo "no $X (or empty)"
			fi
		elif [ $Y = 0 ]
		then
			echo "no servers in $X"
		elif [ ! -s $TMP ]
		then
			echo "no output from ntpq"
		else
			cat $TMP
		fi
	fi
	if [ _"$Y" = _ -o "$Y" = 0 ]
	then
		[ _"$QUIET" = _ ] && echo "NTP not in use"
		return 0
	fi
	if [ ! -s $TMP ]
	then
		cp /dev/null $TMP.x
	else
		TITLE=`head -2 $TMP`
		$TAIL +3 $TMP > $TMP.x
		rm -f $TMP $TMP.y
		while read LINE
		do
			# extract stratum
			X=`expr "$LINE" : "................................  *\([0-9]*\) .*"`
			if [ _"$X" = _ ]
			then
				X=10	# generally LOCAL stratum
			fi
			Y=`echo "$LINE" | cut -c1`
			if [ "$X" -lt $LO -a "(" "$Y" = "*" -o "$Y" = "+" -o "$Y" = "-" ")" ]
			then
				echo "" >> $TMP	# locked on with low stratum
				continue
			fi
			if [ "$X" -gt $HI ]
			then
				echo "$LINE    *****"	# high stratum
			else
				echo "$LINE"	# not high stratum
			fi >> $TMP.y
		done < $TMP.x
	fi

	NTP_FUDGE=/tmp/ohc_ntp_fudge.tmp
	if [ -s $TMP ]
	then
		if [ _"$QUIET" = _ ]
		then
			printf "NTP OK"	# no CR
			if [ -s $TMP.y ]
			then
				printf " (+ other noise from ntpq -p)"
			fi
			echo ""
		fi
		rm -f $NTP_FUDGE
		return 0
	fi
	[ -s $TMP.y ] && grep "^[*+]" $TMP.y > $TMP
	if [ -s $TMP ]
	then
		echo "NTP lock but high stratum"
	else
		# some pathetically unreliable systems lose sync frequently
		# so implement a simple "two-strikes and you're out" policy
		# (disadvantage is if time between scans is large)
		[ -f $NTP_FUDGE ] && echo "NTP not locked" || touch $NTP_FUDGE
	fi
	return 1
}

ohc_uptime()
{
	LO=60
	HI=90

	X=`uptime | tail -1`
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "uptime check"
		echo "$X"
	fi
	# extract actual uptime
	X=`expr "$X" : ".* up[ $TAB][ $TAB]*\(.*\)[ $TAB][ $TAB]*[0-9][0-9]* user.*"`
	if [ _"$X" = _ ]
	then
		echo "can't determine uptime"
		return 1
	fi
	Y=`expr "$X" : "\([0-9]* min\)"`
	if [ _"$Y" != _ ]
	then
		Y=0	# only been up for minutes - call it zero days
	else
		Y=`expr "$X" : "\([0-9]*:[0-9]*\)"`
		if [ _"$Y" != _ ]
		then
			Y=0	# only been up for hours - call it zero days
		else
			Y=`expr "$X" : "\([0-9]*\) day.*"`
		fi
	fi
	if [ _"$Y" = _ ]
	then
		echo "$X"
		return 1
	fi
	if [ $Y -lt $LO ]
	then
		[ _"$QUIET" = _ ] && echo "uptime OK"
		return 0
	fi
	if [ $Y -gt $HI ]
	then
		echo "uptime $Y days    *****"
	else
		echo "uptime $Y days"
	fi
	return 1
}

ohc_load()
{
	LO=15
	HI=20

	X=`uptime | tail -1`
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "load check"
		echo "$X"
	fi
	# examine the 15 min average (truncate to integer)
	Y=`expr "$X" : ".* load average: .*, \([0-9][0-9]*\)\..*"`
	if [ _"$Y" = _ ]
	then
		echo "$X"
		return 1
	fi
	if [ $Y -lt $LO ]
	then
		[ _"$QUIET" = _ ] && echo "load OK"
		return 0
	fi
	if [ $Y -gt $HI ]
	then
		echo "load $Y    *****"
	else
		echo "load $Y"
	fi
	return 1
}

ohc_network()
{
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "default route check"
	fi
	if [ "$OS_VERSION" = SunOS ]
	then
		X=`netstat -rn | grep "^default .* UG " | tail -1`
		X=`expr "$X" : "[a-z]*  *\([0-9.]*\)  *UG "`
	else	# Linux
		X=`netstat -rn | grep "^0\.0\.0\.0 .* UG " | tail -1`
		X=`expr "$X" : "[0.]*  *\([0-9.]*\)  *0\.0\.0\.0  *UG "`
	fi
	if [ _"$X" = _ ]
	then
		echo "no default route"
		return 1
	fi
	do_ping "$X"	# routers often configured to ignore/drop ICMP
	if [ "$?" != 0 ]
	then
		echo "can't ping default route $X"
		return 1
	fi
	[ _"$QUIET" = _ ] && echo "default route OK"

	X=/etc/resolv.conf
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "$X nameservers check"
	fi
	if [ ! -f $X ]
	then
		[ _"$QUIET" = _ ] && echo "$X not found"
		return 0
	fi
	grep "^nameserver" $X > $TMP
	if [ ! -s $TMP ]
	then
		[ _"$QUIET" = _ ] && echo "no nameservers listed"
		return 0
	fi
	rm -f $TMP.e
	while read LINE
	do
		X=`expr "$LINE" : "nameserver[ $TAB]*\([0-9.]*\)\$"`
		if [ _"$X" = _ ]
		then
			echo "bad nameserver" >> $TMP.e
			continue
		fi
		if [ "$X" = "0.0.0.0" ]
		then
			[ _"$VERBOSE" != _ ] && echo "$X skipped"
			continue
		fi
		# see if nameserver is reachable - ask it about itself
		nslookup $X $X | grep "\.in-addr\.arpa[ $TAB]" > $TMP.x
		if [ "$?" != 0 ]
		then
			echo "nameserver $X can't resolve own IP" >> $TMP.e
			continue
		fi
		if [ ! -s $TMP.x ]
		then
			echo "unexpected nameserver $X response" >> $TMP.e
			continue
		fi
		[ _"$VERBOSE" != _ ] && cat $TMP.x
	done < $TMP
	if [ -s $TMP.e ]
	then
		cat $TMP.e
		rm $TMP.e
		return 1
	fi
	[ _"$QUIET" = _ ] && echo "nameservers OK"
	return 0
}

do_ping()
{
	IP="$1"

	if [ "$OS_VERSION" = SunOS ]
	then
		[ _"$VERBOSE" != _ ] && echo "ping $IP"
		Y=`ping $IP | tail -1`
		[ _"$VERBOSE" != _ ] && echo "$Y"
		Y=`expr "$Y" : ".* \(is alive\)"`
		if [ _"$Y" != _ ] ; then return 0 ; fi
	else	# Linux
		[ _"$VERBOSE" != _ ] && echo "ping -c1 $IP"
		Y=`ping -c1 $IP | grep " received" | tail -1`
		[ _"$VERBOSE" != _ ] && echo "$Y"
		Y=`expr "$Y" : ".* \([0-9][0-9]*\) received.*"`
		if [ _"$Y" != _ -a "$Y" = 1 ] ; then return 0 ; fi
	fi
	return 1
}

ohc_eth()
{
	rm -f $TMP.e
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "ethernets check"
	fi
	if [ "$OS_VERSION" = SunOS ]
	then
		for i in `ls /etc | grep "^hostname\."`
		do
			i=`expr "$i" : "hostname.\(.*\)"`
			# ignore aliased interfaces
			X=`expr "$i" : ".*\(:\)"`
			if [ _"$X" != _ ] ; then continue ; fi
			# worry about USB interfaces if ever used
			X=`expr "$i" : "\(usb\).*"`
			if [ _"$X" != _ ] ; then continue ; fi
			echo $i
		done | sort > $TMP	# list of devices that should be active
		while read LINE
		do
			X=`expr "$LINE" : "aggr[0-9][0-9]*\([0-9][0-9][0-9]\)\$"`
			if [ _"$X" != _ ]
			then
				dladm show-aggr $X | grep -v "^key:" |
				    grep -v "device.*address.*speed" |
				    sed -e "s/[ $TAB][ $TAB]*/ /g" -e "s/^ //" -e "s/ [^ ][^ ]* / /" > $TMP.a
				while read LINE
				do
					[ _"$VERBOSE" != _ ] && echo "aggr $X: $LINE"
					Y=`expr "$LINE" : "\([^ ]*\) "`
					Z=`expr "$LINE" : "\($Y 1000 Mbps full up attached\)\$"`
					if [ _"$Z" = _ ]
					then
						echo "aggr $X dev $Y unexpected state"
						echo "" > $TMP.e
					fi
				done < $TMP.a
				rm $TMP.a
				continue
			fi
			X=`dladm show-dev $LINE`
			if [ _"$X" = _ ]
			then
				echo "$LINE not found in dladm output"
				echo "" > $TMP.e
				continue
			fi
			i=`expr "$X" : ".*[ $TAB]speed:[ $TAB]*\([0-9][0-9]*\)[ $TAB]"`
			if [ _"$i" = _ ]
			then
				echo "$LINE can't find speed in dladm output"
				echo "" > $TMP.e
				continue
			fi
			if [ _"$VERBOSE" != _ ]
			then
				echo "$X"
				echo "$LINE speed = $i"
			elif [ _"$i" != _1000 ]	# non-standard
			then
				echo "$LINE not 1000 Mbps"
				echo "" > $TMP.e
			fi
			i=`expr "$X" : ".*[ $TAB]duplex:[ $TAB]*\([^ $TAB]*\)"`
			if [ _"$i" = _ ]
			then
				echo "$LINE can't find duplex in dladm output"
				echo "" > $TMP.e
				continue
			fi
			if [ _"$VERBOSE" != _ ]
			then
				echo "$X"
				echo "$LINE duplex = $i"
			elif [ _"$i" != _full ]	# non-standard
			then
				echo "$LINE not FULL duplex"
				echo "" > $TMP.e
			fi
		done < $TMP
		rm $TMP
	elif [ "$OS_VERSION" = Linux ]
	then
		# check active interfaces are 100Mb/s or 1000Mb/s full duplex
		# (worry about exceptions when there are some)
		N=/etc/sysconfig/network-scripts

		for i in `ls $N | grep "^ifcfg-eth"`
		do
			grep ONBOOT=yes $N/$i > $TMP
			if [ ! -s $TMP ] ; then continue ; fi
			i=`expr "$i" : "ifcfg-\(.*\)"`
			# ignore aliased interfaces
			X=`expr "$i" : ".*\(:\)"`
			if [ _"$X" != _ ] ; then continue ; fi
			ifconfig $i | grep " UP " > $TMP
			if [ ! -s $TMP ]
			then
				echo "$i not UP"
				echo "" > $TMP.e
				continue
			fi
			ethtool $i > $TMP 2> /dev/null
			if [ $? != 0 -o ! -s $TMP ]
			then
				echo "ethtool $i failed"
				echo "" > $TMP.e
				continue
			fi
			if [ _"$VERBOSE" != _ ]
			then
				X=`grep "Speed:" $TMP | tail -1`
				X=`expr "$X" : ".*Speed: *\(.*\)"`
				echo "$i speed $X"
				X=`grep "Duplex:" $TMP | tail -1`
				X=`expr "$X" : ".*Duplex: *\(.*\)"`
				echo "$i duplex $X"
			else
				X=`grep "Speed: " $TMP | tail -1`
				X=`expr "$X" : ".*Speed: *\([0-9]*\)Mb/s"`
				if [ _"$X" != _100 -a _"$X" != _1000 ]
				then
					if [ _"$X" = _10 ]
					then
						echo "$i 10Mb/s"
					else
						echo "$i speed unknown"
					fi
					echo "" > $TMP.e
				fi
				X=`grep "Duplex: " $TMP | tail -1`
				X=`expr "$X" : ".*Duplex: *\([^ ]*\)"`
				if [ _"$X" != _Full ]
				then
					if [ _"$X" = _Half ]
					then
						echo "$i half duplex"
					else
						echo "$i duplex unknown"
					fi
					echo "" > $TMP.e
				fi
			fi
		done
		rm -f $TMP
	fi
	if [ -s $TMP.e ]
	then
		rm $TMP.e
		return 1
	fi
	[ _"$QUIET" = _ ] && echo "ethernets OK"
	return 0
}

ohc_who()
{
	RET=0
	who > $TMP
	if [ _"$VERBOSE" != _ ]
	then
		echo ""
		echo "check logons"
		cat $TMP
	fi
	grep "^root[ $TAB]" $TMP > $TMP.x
	if [ -s $TMP.x ]
	then
		X=`wc -l < $TMP.x`
		X=`echo $X`	# strip leading blanks
		echo "root logged on $X times:"
		sed -e "s/root[ $TAB]*//" -e "s/[ $TAB].*//" $TMP.x |
		    while read LINE
		do
			printf " $LINE"	# no CR
		done
		echo ""
		RET=1
	fi
	# want to detect abandoned logons that may have output loops running
	# (e.g. top, vmstat) so device mtime and SunOS "who -T" insufficient;
	# if run just prior to midnight can look for logons before today
	# (but note script may be run several times a day?)
	X=`date "+%b %e "`
	grep -v "$X" $TMP > $TMP.x
	if [ -s $TMP.x ]
	then
		X=`wc -l < $TMP.x`
		X=`echo $X`	# strip leading blanks
		echo "$X logons before today:"
		cat $TMP.x
		RET=1
	fi
	[ _"$RET" != _0 ] && return 1
	[ _"$QUIET" = _ ] && echo "logons OK"
	return 0
}

NAME=`hostname | cut -f1 -d.`
OS_VERSION=`uname -s`

case "$OS_VERSION"
in
Linux)
	PATH=/usr/local/bin:/sbin:/usr/sbin:/bin:/usr/bin
	TAIL="tail -n"
	;;
SunOS)
	PATH=/usr/local/bin:/sbin:/usr/sbin:/etc:/bin:/usr/bin:/usr/ucb
	TAIL=tail
	;;
*)
	echo "$OS_VERSION unknown - exit"
	Exit 1
	;;
esac

# pre-digest exceptions-list to simplify subsequent testing
EXCEPT=`echo "$EXCEPT" | sed -e "s/[ $TAB][ $TAB]*/ /g"`
EXCEPT=`echo "$EXCEPT" | sed "s/^ //"`
EXCEPT=`echo "$EXCEPT" | sed -e "s/#.*//" -e "s/ \$//" -e "/^\$/d"`

ohc_df || STATUS=1
ohc_dfi || STATUS=1
ohc_swap || STATUS=1
if [ "$OS_VERSION" = SunOS ]
then
	ohc_swapx || STATUS=1
	ohc_svm || STATUS=1
fi
ohc_ntp || STATUS=1
#ohc_uptime || STATUS=1
#ohc_load || STATUS=1
ohc_network || STATUS=1
ohc_eth || STATUS=1
#ohc_who || STATUS=1

rm -f $TMP $TMP.*
if [ _"$LOCAL" != _ ]
then
	X=
	[ _"$QUIET" != _ ] && X=-q
	[ _"$VERBOSE" != _ ] && X=-v
	sh $LOCAL $X || STATUS=1
fi

Exit

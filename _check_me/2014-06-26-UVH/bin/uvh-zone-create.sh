#!/bin/sh

# create zone
#    shared or exclusive IP (exclusive requires limited interface types)
#    native solaris 10 (image file optional), or branded solaris 8 or 9
#	(requires image files)
#    whole-root or sparse-root
#	whole-root: copies around 156500 files occupying 4.1Gb
#	sparse-root: copies around 8200 files occupying 0.6Gb
#	    loopback-mounts /lib /platform /sbin /usr read-only
#    optional capped cpu threads
#	may link to existing pset or pool, or create new ones;
#	alternatively may use capped-cpu configuration option
#    optional capped memory
#    optional capped swap (but only if memory capped)
#    optional filesystem loopbacks
#    preconfigures zone using /etc/sysidcfg (including NETMASK in shared-IP
#	model for completeness) to avoid first-boot tedium - asks for locale

# will accept default answers from a zonecfg-install type file
# relies on expr being greater than 32-bit capable

PING_TIMEOUT=5	# ping timeout, seconds (default 20)
POOLADMCONF=/etc/pooladm.conf

TMP=/tmp/mz.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

TAB='	'	# care - tab (don't cut and paste)
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

# turn dot-notation IP into a decimal equivalent for easy comparisons
# (no output if error in IP - can be used below as sanity check)
ip2dec()
{
	X_IP="$1"

	X_NOISE=x
	X_IP="$X_IP.$X_NOISE"
	X_NUM=0
	for i in 1 2 3 4
	do
		X_NUM=`expr $X_NUM \* 256`
		X_X=`expr "$X_IP" : "\([0-9][0-9]*\).*"`
		[ _"$X_X" = _ ] && return
		X_NUM=`expr $X_NUM + $X_X`
		X_IP=`expr "$X_IP" : "[0-9][0-9]*\.\(.*\)"`
		[ _"$X_IP" = _ ] && return
	done
	[ _"$X_IP" = _$X_NOISE ]&& echo $X_NUM
}

# turn decimal number string into dot-notation IP
decstr2ip()
{
	X_NUM="$1"

	X_X=`expr "$X_NUM" : "\([0-9]*\)"`
	[ _"$X_X" != _"$X_NUM" ] && return
	X_IP=
	X_N=0
	while [ $X_N -lt 4 ]
	do
		X_X=`expr "$X_NUM" % 256`
		X_NUM=`expr "$X_NUM" / 256`
		if [ _"$X_IP" = _ ]
		then
			X_IP="$X_X"
		else
			X_IP="$X_X.$X_IP"
		fi
		X_N=`expr $X_N + 1`
	done
	[ _"$X_NUM" = _0 ] && echo $X_IP
}

# turn hexadecimal number string into dot-notation IP
hexstr2ip()
{
	X_NUM="$1"

	X_NUM=`echo "$X_NUM" | tr "[A-Z]" "[a-z]"`
	X_X=`expr "$X_NUM" : "\([0-9a-f]*\)"`
	[ _"$X_X" != _"$X_NUM" ] && return
	X_X=`expr "$X_NUM" : ".*"`
	[ $X_X -ne 8 ] && return
	X_IP=
	for i in 1 2 3 4
	do
		X_X=`expr "$X_NUM" : ".*\(..\)"`
		X_NUM=`expr "$X_NUM" : "\(.*\).."`
		X_X=`hexstr2dec "$X_X"`
		if [ _"$X_IP" = _ ]
		then
			X_IP="$X_X"
		else
			X_IP="$X_X.$X_IP"
		fi
	done
	echo $X_IP
}

masksz2ip()
{
	case $1
	in
	4)	echo 240.0.0.0 ;;
	5)	echo 248.0.0.0 ;;
	6)	echo 252.0.0.0 ;;
	7)	echo 254.0.0.0 ;;
	8)	echo 255.0.0.0 ;;
	9)	echo 255.128.0.0 ;;
	10)	echo 255.192.0.0 ;;
	11)	echo 255.224.0.0 ;;
	12)	echo 255.240.0.0 ;;
	13)	echo 255.248.0.0 ;;
	14)	echo 255.252.0.0 ;;
	15)	echo 255.254.0.0 ;;
	16)	echo 255.255.0.0 ;;
	17)	echo 255.255.128.0 ;;
	18)	echo 255.255.192.0 ;;
	19)	echo 255.255.224.0 ;;
	20)	echo 255.255.240.0 ;;
	21)	echo 255.255.248.0 ;;
	22)	echo 255.255.252.0 ;;
	23)	echo 255.255.254.0 ;;
	24)	echo 255.255.255.0 ;;
	25)	echo 255.255.255.128 ;;
	26)	echo 255.255.255.192 ;;
	27)	echo 255.255.255.224 ;;
	28)	echo 255.255.255.240 ;;
	29)	echo 255.255.255.248 ;;
	30)	echo 255.255.255.252 ;;
	31)	echo 255.255.255.254 ;;
	*)	;;
	esac
}

# turn hexadecimal number string into a decimal equivalent
hexstr2dec()
{
	X_STR="$1"

	X_DEC=0
	while [ _"$X_STR" != _ ]
	do
		X_VAL=`expr "$X_STR" : "\(.\).*" | tr "[A-Z]" "[a-z]"`
		case $X_VAL
		in
		0|1|2|3|4|5|6|7|8|9)
			;;
		a)	X_VAL=10 ;;
		b)	X_VAL=11 ;;
		c)	X_VAL=12 ;;
		d)	X_VAL=13 ;;
		e)	X_VAL=14 ;;
		f)	X_VAL=15 ;;
		*)	return
		esac
		X_DEC=`expr $X_DEC \* 16 + $X_VAL`
		X_STR=`expr "$X_STR" : ".\(.*\)"`
	done
	echo $X_DEC
}

get_zdir()
{
	if [ _"$FN" != _ ]
	then
		DFLT=`grep " zonepath=" $FN | cut -f2 -d=`
		DFLT=`expr "$DFLT" : "\(.*\)\/"`
	else
		DFLT=
	fi
	[ _"$DFLT" = _ ] && DFLT=/zones
	echo "directory that zone will be created under (must be root-owned): [$DFLT] \c"
	read ZONE_DIR
	[ _"$ZONE_DIR" = _ ] && ZONE_DIR=$DFLT
	X=`echo "$ZONE_DIR" | cut -c1`
	if [ _"$X" != _/ ]
	then
		echo "must start with /"
		echo ""
		ZONE_DIR=
		return 1
	fi
	return 0
}

get_zname()
{
	if [ _"$FN" != _ ]
	then
		DFLT=`grep " zonepath=" $FN | cut -f2 -d=`
		DFLT=`expr "$DFLT" : ".*\/\(.*\)"`
	else
		DFLT=
	fi
	X=`zoneadm list | grep -v "^global\$" | sort`
	if [ _"$X" != _ ]
	then
		echo "existing zones:"
		for i in $X
		do
			echo "$TAB$i"
		done
		echo ""
	fi
	echo "new zone name: \c"
	[ _"$DFLT" != _ ] && echo "[$DFLT] \c"
	read ZONE_NAME
	if [ _"$ZONE_NAME" = _ ]
	then
		ZONE_NAME=$DFLT
		[ _"$ZONE_NAME" = _ ] && return 1
	fi
	X=`expr "$ZONE_NAME" : "\([a-zA-Z0-9][A-Za-z0-9_-]*\)"`
	if [ _"$ZONE_NAME" != _"$X" ]
	then
		echo "zone name <$ZONE_NAME> invalid"
		echo "    must be alphanumerics then alphanumerics or - or _"
		ZONE_NAME=
		return 1
	fi
	if [  _"$ZONE_NAME" = _global ]
	then
		echo "zone name may not be \"global\""
		echo ""
		ZONE_NAME=
		return 1
	fi
	X=`hostname | cut -f1 -d.`
	if [ _"$ZONE_NAME" = _"$X" ]
	then
		echo "zone name may not be same as physical host name"
		echo ""
		ZONE_NAME=
		return 1
	fi
	X=`expr "$ZONE_NAME" : "\(SUNW\)"`
	if [ _"$X" != _ ]
	then
		echo "zone name may not start with SUNW"
		echo ""
		ZONE_NAME=
		return 1
	fi
	zonecfg -z $ZONE_NAME info > $TMP 2>&1
	X=`grep "No such zone" $TMP`
	if [ _"$X" = _ ]
	then
		X=`grep zonepath $TMP | cut -f2 -d' '`
		cat <<!
zone $ZONE_NAME already exists - IF you want to remove it:
zoneadm -z $ZONE_NAME halt
zoneadm -z $ZONE_NAME uninstall -F
zonecfg -z $ZONE_NAME delete -F
(umount & rmdir $X)

!
		rm $TMP
		ZONE_NAME=
		return 1
	fi
	rm $TMP
	X=`ls -ld "$ZONE_DIR/$ZONE_NAME" 2> /dev/null`
	[ _"$X" = _ ] && return 0
	ls -a "$ZONE_DIR/$ZONE_NAME" |
	    egrep -v "^\.\$|^\.\.\$|^lost\+found\$" > $TMP
	echo "$ZONE_DIR/$ZONE_NAME already exists \c"
	if [ ! -s $TMP ]
	then
		echo "but is empty"
		df -h "$ZONE_DIR/$ZONE_NAME"
		rm $TMP
		echo ""
		return 0
	fi
	rm $TMP
	echo "and is not empty - must be removed first"
	echo ""
	ZONE_NAME=
	return 1
}

get_zIPtype()
{
	if [ _"$FN" != _ ]
	then
		DFLT=`grep "^add net" $FN`
		if [ _"$DFLT" = _ ]
		then
			DFLT=n
		else
			DFLT=`grep " ip-type=" $FN | tail -1 | cut -f2 -d=`
			[ _"$DFLT" = _exclusive ] && DFLT=e || DFLT=s
		fi
	else
		DFLT=s
	fi
	echo "ip-type: (e)xclusive (limited hardware), (s)hared, (n)one: [$DFLT] \c"
	read IP_TYPE
	[ _"$IP_TYPE" = _ ] && IP_TYPE=$DFLT
	IP_TYPE=`echo "$IP_TYPE" | tr "[A-Z]" "[a-z]"`
	[ _"$IP_TYPE" != _e -a _"$IP_TYPE" != _n ] && IP_TYPE=s
}

get_zIP()
{
	# try to set a default - check config file, see if known to DNS,
	# or if already set in /etc/hosts
	DFLT=
	[ _"$FN" != _ ] && DFLT=`grep " address=" $FN | tail -1 | cut -f2 -d=`
	if [ _"$DFLT" = _ ]
	then
		DFLT=`nslookup "$ZONE_NAME" | tail +3 | grep Address: | cut -d' ' -f2`
	fi
	X=`ip2dec "$DFLT"`	# sanity check
	if [ _"$X" = _ ]
	then
		DFLT=`grep "[ $TAB]$ZONE_NAME[ $TAB]" /etc/hosts | tail -1`
		if [ _"$DFLT" = _ ]
		then
			DFLT=`grep "[ $TAB]$ZONE_NAME\$" /etc/hosts | tail -1`
		fi
		DFLT=`echo "$DFLT" | cut -d' ' -f1 | cut -d"$TAB" -f1`
		X=`ip2dec "$DFLT"`	# sanity check
		[ _"$X" = _ ] && DFLT=
	fi
	echo "zone IP: \c"
	[ _"$DFLT" != _ ] && echo "[$DFLT] \c"
	read NET_IP
	if [ _"$NET_IP" = _ ]
	then
		NET_IP=$DFLT
		[ _"$NET_IP" = _ ] && return 1
	fi
	NET_IP_NUM=`ip2dec "$NET_IP"`
	if [ _"$NET_IP_NUM" = _ ]
	then
		echo "IP <$NET_IP> invalid"
		NET_IP=
		return 1
	fi
	echo "ping test..."
	ping "$NET_IP" $PING_TIMEOUT > /dev/null 2>&1
	if [ $? = 0 ]
	then
		echo "$NET_IP is alive - choose another..."
		NET_IP=
		return 1
	fi
	echo "$NET_IP OK (did not respond)"
	[ _"$IP_TYPE" != _e ] && return 0
	echo "netmask (bits or dot-decimal pattern): \c"
	read NETMASK
	[ _"$NETMASK" = _ ] && return 1
	X=`expr "$NETMASK" : "\([0-9][0-9]*\)\$"`
	if [ _"$X" = _"$NETMASK" ]
	then
		NETMASK=`masksz2ip $X`
		if [ _"$NETMASK" = _ ]
		then
			echo "invalid netmask bitsize $X"
			return 1
		fi
	else
		X=`ip2dec $NETMASK`
		if [ _"$X" = _ ]
		then
			echo "$NETMASK invalid dot-decimal"
			NETMASK=
			return 1
		fi
		case $X
		in
		4026531840|\
		4160749568|4227858432|4261412864|4278190080|\
		4286578688|4290772992|4292870144|4293918720|\
		4294443008|4294705152|4294836224|4294901760|\
		4294934528|4294950912|4294959104|4294963200|\
		4294965248|4294966272|4294966784|4294967040|\
		4294967168|4294967232|4294967264|4294967280|\
		4294967288|4294967292|4294967294)
			;;
		*)	echo "invalid netmask value"
			NETMASK=
			return 1
			;;
		esac
	fi
	return 0
}

get_zif()
{
	DFLT=
	X_N=0
	echo "suitable network interfaces:"
	if [ _"$IP_TYPE" = _e ]
	then
		dladm show-dev | cut -f1 -d"$TAB" | sort > $TMP.dl
		ifconfig -a | grep -v "^[ $TAB]" | cut -f1 -d: > $TMP.if
		dladm show-link | grep ": vlan " | sed "s/.*: //" >> $TMP.if
		for i in `zoneadm list | grep -v "^global\$"`
		do
			zonecfg -z $i info | grep physical: |
			    sed -e "s/.*physical: *//"
		done >> $TMP.if
		sort -u $TMP.if -o $TMP.if
		for i in `comm -23 $TMP.dl $TMP.if`
		do
			echo "$TAB$i"
			DFLT=$i
			X_N=`expr $X_N + 1`
		done
		rm $TMP.dl $TMP.if
		if [ $X_N -ne 1 ]
		then
			if [ _"$FN" != _ ]
			then
				DFLT=`grep " physical=" $FN | tail -1 | cut -f2 -d=`
			else
				DFLT=
			fi
		fi
		echo ""
		echo "physical network interface: \c"
		[ _"$DFLT" != _ ] && echo "[$DFLT] \c"
		read NET_PHYSICAL
		if [ _"$NET_PHYSICAL" = _ ]
		then
			NET_PHYSICAL=$DFLT
			[ _"$NET_PHYSICAL" = _ ] && return 1
		fi
		X=`ifconfig "$NET_PHYSICAL" 2>&1 | grep inet`
		if [ _"$X" != _ ]
		then
			echo "interface <$NET_PHYSICAL> used in global"
			NET_PHYSICAL=
			return 1
		fi
		return 0
	fi
	for i in `ifconfig -a | grep UP | grep -v PRIV | cut -f1 -d: | sort -u | grep -v lo`
	do
		X=`ifconfig $i | grep inet`
		Y=`expr "$X" : ".* netmask  *\([^ ]*\) .*"`
		X_X=`hexstr2ip "$Y"`
		if [ _"$X_X" = _ ]
		then
			echo "$i: can't determine netmask"
			continue
		fi
		X=`expr "$X" : ".*inet  *\([^ ]*\) .*"`
		X_X=`ip2dec "$X"`
		if [ _"$X_X" = _ ]
		then
			echo "$i: can't determine IP"
			continue
		fi
		case $Y		# convert to 2^32 - mask
		in
		fffffffc)	Y=4 ;;
		fffffff8)	Y=8 ;;
		fffffff0)	Y=16 ;;
		ffffffe0)	Y=32 ;;
		ffffffc0)	Y=64 ;;
		ffffff80)	Y=128 ;;
		ffffff00)	Y=256 ;;
		fffffe00)	Y=512 ;;
		fffffc00)	Y=1024 ;;
		fffff800)	Y=2048 ;;
		fffff000)	Y=4096 ;;
		ffffe000)	Y=8192 ;;
		ffffc000)	Y=16384 ;;
		ffff8000)	Y=32768 ;;
		ffff0000)	Y=65536 ;;
		fffe0000)	Y=131072 ;;
		fffc0000)	Y=262144 ;;
		fff80000)	Y=524288 ;;
		fff00000)	Y=1048576 ;;
		ffe00000)	Y=2097152 ;;
		ffc00000)	Y=4194304 ;;
		ff800000)	Y=8388608 ;;
		ff000000)	Y=16777216 ;;
		fe000000)	Y=33554432 ;;
		fc000000)	Y=67108864 ;;
		f8000000)	Y=134217728 ;;
		f0000000)	Y=268435456 ;;
		*)		echo "$i: bad netmask" ; continue ;;
		esac
		X_LO=`expr $X_X % $Y`
		X_LO=`expr $X_X - $X_LO`
		X_HI=`expr $X_LO + $Y`
		if [ $NET_IP_NUM -ge $X_LO -a $NET_IP_NUM -lt $X_HI ]
		then
			echo "$TAB$i"
			DFLT=$i
			X_N=`expr $X_N + 1`
		fi
	done
	[ $X_N -eq 0 ] && echo "${TAB}(none)"
	if [ $X_N -ne 1 ]
	then
		if [ _"$FN" != _ ]
		then
			DFLT=`grep " physical=" $FN | tail -1 | cut -f2 -d=`
		else
			DFLT=
		fi
	fi
	echo ""
	echo "physical network interface: \c"
	[ _"$DFLT" != _ ] && echo "[$DFLT] \c"
	read NET_PHYSICAL
	if [ _"$NET_PHYSICAL" = _ ]
	then
		[ _"$DFLT" = _ ] && return 1
		NET_PHYSICAL=$DFLT
	fi
	X=`ifconfig "$NET_PHYSICAL" 2>&1 | grep inet`
	if [ _"$X" = _ ]
	then
		echo "interface <$NET_PHYSICAL> unknown"
		NET_PHYSICAL=
		return 1
	fi
	NETMASK=`expr "$X" : ".* netmask  *\([^ ]*\) .*"`
	X=`hexstr2dec $NETMASK`
	X=`expr 4294967296 - $X`
	NETWORK=`ip2dec $NET_IP`
	X=`expr $NETWORK % $X`
	NETWORK=`expr $NETWORK - $X`
	NETWORK=`decstr2ip $NETWORK`
	NETMASK=`hexstr2ip "$NETMASK"`
	if [ _"$NETMASK" = _ ]
	then
		echo "can't determine netmask for $NET_PHYSICAL"
		NET_PHYSICAL=
		return 1
	fi
	grep . /etc/netmasks | grep -v "^#" |
	    sed "s/[ $TAB][ $TAB]*/$TAB/g" |
	    sed "s/^$TAB//" | sed "s/$TAB\$//" | sort > $TMP
	echo "$NETWORK$TAB$NETMASK" > $TMP.x
	sort -u $TMP $TMP.x -o $TMP.x
	cmp -s $TMP $TMP.x
	if [ $? != 0 ]
	then
		echo "subnet $NETWORK/$NETMASK is missing from the global /etc/netmasks"
		echo "  which will generate syslog WARNINGS when the zone is booted"
		echo ""
		if [ -s $TMP ]
		then
			echo "/etc/netmasks contents:"
			cat $TMP
			echo ""
		fi
		echo "add subnet to global /etc/netmasks? ([y]/n) \c"
		read ANS
		echo ""
		ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
		[ _"$ANS" != _n ] &&
		    echo "$NETWORK$TAB$NETMASK" >> /etc/netmasks
	fi
	rm $TMP $TMP.x
	return 0
}

get_zbrand()
{
	if [ _"$FN" != _ ]
	then
		DFLT=`grep "^create -t SUNWsolaris[89]\$" $FN`
		if [ _"$DFLT" = _ ]
		then
			DFLT=n
		else
			DFLT=`expr "$DFLT" : ".*\(.\)"`
		fi
	else
		DFLT=n
	fi
	echo "native (sol10) or branded (sol8 or sol9): (\c"
	if [ _"$DFLT" = _n ]
	then
		echo "[n]|8|9\c"
	elif [ _"$DFLT" = _9 ]
	then
		echo "n|8|[9]\c"
	else
		echo "n|[8]|9\c"
	fi
	echo ") \c"
	read ZBRAND
	if [ _"$ZBRAND" = _ ]
	then
		ZBRAND=$DFLT
	else
		ZBRAND=`echo "$ZBRAND" | tr "[A-Z]" "[a-z]"`
	fi
	if [ _"$ZBRAND" != _8 -a _"$ZBRAND" != _9 ]
	then
		ZBRAND=n
		return 0
	fi
	pkginfo | grep " SUNWs${ZBRAND}brand[kru] " > $TMP
	Y=
	for i in k r u
	do
		X=`grep " SUNWs${ZBRAND}brand$i " $TMP`
		if [ _"$X" = _ ]
		then
			echo "missing package SUNWs${ZBRAND}brand$i"
			Y=true
		fi
	done
	rm $TMP
	if [ _"$Y" != _ ]
	then
		ZBRAND=
		return 1
	fi
	return 0
}

get_zimagef()
{
	while true
	do
		if [ _"$ZBRAND" = _n ]
		then
			echo "(optional) file containing (configured) native image (CR if none)\c"
		else
			echo "file containing solaris$ZBRAND image\c"
		fi
		echo " (!cmnd): \c"
		read IMAGEF
		if [ _"$IMAGEF" = _ ]
		then
			if [ _"$ZBRAND" = _n ]
			then
				IMAGEF=!
				return 0
			fi
			continue
		fi
		X=`echo "$IMAGEF" | cut -c1`
		[ _"$X" != _! ] && break
		# allow shell-escape to look for image file!
		IMAGEF=`echo "$IMAGEF" | cut -c2-`
		if [ _"$IMAGEF" != _ ]
		then
			sh -c "$IMAGEF"
		fi
		echo "!"
	done
	if [ _"$X" != _/ ]
	then
		# stupid install command needs full path
		IMAGEF=`pwd`/"$IMAGEF"
	fi
	if [ ! -f "$IMAGEF" ]
	then
		echo "can't find $IMAGEF"
		IMAGEF=
		return 1
	fi
	if [ _"$ZBRAND" = _n ]
	then
		IMAGEFFLAG=p
	else
		echo "is this image unconfigured (e.g. Sun-supplied branded zone image), or"
		echo " should the image identity be preserved (e.g. working system image)? (u|[p]) \c"
		read IMAGEFFLAG
		IMAGEFFLAG=`echo "$IMAGEFFLAG" | tr "[A-Z]" "[a-z]"`
		[ _"$IMAGEFFLAG" != _u ] && IMAGEFFLAG=p
	fi
	ZROOT=w	# must be whole-root zone
	return 0
}

get_zroottype()
{
	if [ _"$FN" != _ ]
	then
		DFLT=`grep "^create" $FN`
		[ _"$DFLT" = _"create -b" ] && DFLT=w || DFLT=s
	else
		DFLT=w
	fi
	echo "whole-root or sparse-root: (\c"
	[ _"$DFLT" = _w ] && echo "[w]|s\c" || echo "w|[s]\c"
	echo ") \c"
	read ZROOT
	if [ _"$ZROOT" = _ ]
	then
		ZROOT=$DFLT
		return
	fi
	ZROOT=`echo "$ZROOT" | tr "[A-Z]" "[a-z]"`
	[ _"$ZROOT" != _w -a _"$ZROOT" != _s ] && ZROOT=$DFLT
}

get_zcpucap()
{
	NO_POOLS=
	X=`psrset | wc -l | tr -d ' '`
	if [ $X -eq 0 ]
	then
		echo "no processor sets exist"
		NO_POOLS=true
		MAX_THREADS=`psrinfo | wc -l`
	else
		echo "pooladm -s $POOLADMCONF"
		pooladm -s $POOLADMCONF	# ensure current
		echo ""
		echo "$X processor sets exist - summary:"
		echo "pset min/size/max"
		echo "${TAB}pool"
		echo "${TAB}${TAB}zone"
		echo -------------------------
		for i in `zoneadm list | grep -v "^global\$"`
		do
			zonecfg -z $i info | grep pool: | cut -d' ' -f2 > $TMP.zone.$i
		done
		pooladm > $TMP
		for i in `grep "pool " $TMP | grep -v pool_default | cut -d' ' -f2`
		do
			poolcfg -c "info pool $i" | grep pset | head -1 | cut -d"$TAB" -f3 > $TMP.pool.$i
		done
		for i in `grep "pset " $TMP | grep -v pset_default | cut -d' ' -f2 | sort`
		do
			poolcfg -c "info pset $i" | egrep "pset\.min |pset\.max |pset\.size " > $TMP.pset
			ed - $TMP.pset <<!
/min/m\$
/size/m\$
/max/m\$
,s/.* //
1,-s/\$/\//
,j
w
!
			echo "$i `cat $TMP.pset`"
			for j in $TMP.pool.*
			do
				X=`grep "^$i\$" $j`
				[ _"$X" = _ ] && continue
				j=`expr "$j" : ".*\.\(.*\)"`
				echo "${TAB}$j"
				for k in $TMP.zone.*
				do
					X=`grep "^$j\$" $k`
					[ _"$X" = _ ] && continue
					k=`expr "$k" : ".*\.\(.*\)"`
					echo "${TAB}${TAB}$k"
				done
			done
		done
		echo ""
		rm -f $TMP $TMP.pset $TMP.pool.* $TMP.zone.*
		MAX_THREADS=`poolcfg -c "info pset pset_default" | grep pset.size`
	fi
	MAX_THREADS=`expr "$MAX_THREADS" : "[^0-9]*\([0-9][0-9]*\).*"`
	[ _"$MAX_THREADS" = _ ] && MAX_THREADS=0
	echo "limit cpu threads? ([n]|y) \c"
	read ANS
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	if [ _"$ANS" != _y ]
	then
		CPUS=true
		return 0
	fi
	echo "cpu-(c)ap, or cpu-(p)ools? ([c]|p) \c"
	read ANS
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	[ _"$ANS" != _p ] && ANS=c
	if [ _"$ANS" = _c ]
	then
		echo "cpu cap (non-zero, max $MAX_THREADS.00): \c"
		read CPU_CAP
		if [ _"$CPU_CAP" = _ ]
		then
			echo "invalid number"
			return 1
		fi
		# must be digit(s)[.digit(s)]
		X=`expr "$CPU_CAP" : "\([0-9][0-9]*\)"`	# leading digit(s)
		Y=`expr "$CPU_CAP" : ".*\.\([0-9]*\)"`	# trailing digits
		if [ _"$Y" = _ -a _"$CPU_CAP" != _"$X" -o \
		      _"$Y" != _ -a _"$CPU_CAP" != _"$X.$Y" ]
		then
			echo "cpu cap <$CPU_CAP> invalid"
			CPU_CAP=
			return 1
		fi
		if [ _"$X" = _ ]
		then
			X=0
			CPU_CAP="0$CPU_CAP"
		fi
		[ _"$Y" = _ ] && Y=0
		if [ $X -gt $MAX_THREADS -o $X -eq $MAX_THREADS -a $Y -ne 0 ]
		then
			echo "cpu cap <$CPU_CAP> exceeds $MAX_THREADS"
			CPU_CAP=
			return 1
		fi
		if [ $X -eq 0 -a $Y -eq 0 ]
		then
			echo "cpu cap must be non-zero"
			CPU_CAP=
			return 1
		fi
		CPUS=true
		return 0
	fi
	PSET_NAME=ps_$ZONE_NAME
	echo "name for processor set\c"
	[ _"$NO_POOLS" = _ ] && echo " (may already exist)\c"
	echo ": [$PSET_NAME] \c"
	read ANS
	[ _"$ANS" != _ ] && PSET_NAME="$ANS"
	MAKE_PSET=
	if [ _"$NO_POOLS" != _ ]
	then
		MAKE_PSET=true
	else
		X=`poolcfg -c "info pset $PSET_NAME" 2> /dev/null`
		if [ _"$X" = _ ]
		then
			MAKE_PSET=true
		else
			cat <<!
will use existing processor set $PSET_NAME
IF you want to remove it:
poolcfg -c 'destroy pset $PSET_NAME'
pooladm -c
pooladm -s $POOLADMCONF
!
		fi
	fi
	if [ _"$MAKE_PSET" != _ ]
	then
		echo "will create processor set $PSET_NAME"
		echo "max cpu threads: \c"
		if [ $MAX_THREADS -ne 0 ]
		then
			echo "($MAX_THREADS threads uncommitted) \c"
		fi
		read NUM_CPUS
		if [ _"$NUM_CPUS" = _ ]
		then
			echo "invalid number"
			return 1
		fi
		X=`expr "$NUM_CPUS" : "\([0-9]*\)"`
		if [ _"$NUM_CPUS" != _"$X" ]
		then
			echo "num_cpus <$NUM_CPUS> invalid"
			return 1
		fi
		if [ $NUM_CPUS -gt $MAX_THREADS ]
		then
			echo "num_cpus <$NUM_CPUS> exceeds $MAX_THREADS uncommitted"
			return 1
		fi
		if [ $NUM_CPUS -eq 0 ]
		then
			echo "num_cpus must be non-zero"
			return 1
		fi
	fi
	POOL_NAME=pool_$ZONE_NAME
	echo "name for pool\c"
	[ _"$NO_POOLS" = _ -a _"$MAKE_PSET" = _ ] && echo " (may already exist)\c"
	echo ": [$POOL_NAME] \c"
	read ANS
	[ _"$ANS" != _ ] && POOL_NAME="$ANS"
	MAKE_POOL=
	if [ _"$NO_POOLS" != _ ]
	then
		MAKE_POOL=true
	else
		X=`poolcfg -c "info pool $POOL_NAME" 2> /dev/null | grep "pset " | cut -d' ' -f2`
		if [ _"$X" = _ ]
		then
			MAKE_POOL=true
		else
			if [ _"$MAKE_PSET" != _ -o _"$X" != _"$PSET_NAME" ]
			then
				echo "pool $POOL_NAME already exists but does not use pset $PSET_NAME"
				return 1
			fi
			cat <<!
will use existing pool $POOL_NAME
IF you want to remove it:
poolcfg -c 'destroy pool $POOL_NAME'
pooladm -c
pooladm -s $POOLADMCONF
!
		fi
	fi
	if [ _"$MAKE_POOL" != _ ]
	then
		echo "will create pool $POOL_NAME"
	fi
	CPUS=true
	return 0
}

get_zmemcap()
{
	MAX_MEM=`prtconf | grep "^Memory size: [0-9][0-9]* Megabytes\$"`
	MAX_MEM=`expr "$MAX_MEM" : "[^0-9]*\([0-9][0-9]*\).*"`
	if [ _"$MAX_MEM" != _ ]
	then
		for i in `zoneadm list | grep -v "^global\$"`
		do
			X=`zonecfg -z $i info capped-memory | grep "physical: [0-9][0-9]*[MGT]\$"`
			X=`expr "$X" : "[^0-9]*\([0-9][0-9]*.\).*"`
			Y=`expr "$X" : "[0-9]*\(.\)\$"`
			X=`expr "$X" : "\([0-9]*\).\$"`
			if [ _"$Y" = _G ]
			then
				X=`expr $X \* 1024`
			elif [ _"$Y" = _T ]
			then
				X=`expr $X \* 1024 \* 1024`
			fi
			[ _"$X" != _ ] && MAX_MEM=`expr $MAX_MEM - $X`
		done
	fi
	if [ _"$MAX_MEM" = _ ]
	then
		MAX_MEM=0
	elif [ $MAX_MEM -lt 0 ]
	then
		MAX_MEM=0
	fi
	echo "memory cap (Mb)\c"
	[ $MAX_MEM -gt 0 ] && echo " ($MAX_MEM Mb uncommitted)\c"
	echo " [don't care]: \c"
	read MEM_CAP
	X=`expr "$MEM_CAP" : "\([0-9]*\)"`
	if [ _"$MEM_CAP" != _ ]
	then
		if [ _"$MEM_CAP" != _"$X" ]
		then
			echo "memory_cap <$MEM_CAP> invalid"
			MEM_CAP=
			return 1
		fi
		if [ $MEM_CAP -gt $MAX_MEM ]
		then
			echo "warning: $MEM_CAP Mb exceeds $MAX_MEM uncommitted"
		fi
	fi
	return 0
}

get_zswapcap()
{
	echo "swap cap (Mb) [don't care]: \c"
	read SWAP_CAP
	X=`expr "$SWAP_CAP" : "\([0-9]*\)"`
	if [ _"$SWAP_CAP" != _ ]
	then
		if [ _"$SWAP_CAP" != _"$X" ]
		then
			echo "swap_cap <$SWAP_CAP> invalid"
			SWAP_CAP=
			return 1
		fi
		if [ $SWAP_CAP -lt $MEM_CAP ]
		then
			echo "swap cap must not be less than memory cap"
			SWAP_CAP=
			return 1
		fi
	fi
	return 0
}

make_cpupool()
{
	if [ _"$MAKE_PSET" != _ ]
	then
		cat > $TMP <<!
create pset $PSET_NAME ( uint pset.min = $NUM_CPUS ; uint pset.max = $NUM_CPUS )
!
	fi
	if [ _"$MAKE_POOL" != _ ]
	then
		cat >> $TMP <<!
create pool $POOL_NAME
associate pool $POOL_NAME ( pset $PSET_NAME )
!
	fi
	if [ -s $TMP ]
	then
		# check if default config file exists, if not there
		# create one with active configuration
		if [ ! -f $POOLADMCONF ]
		then
			echo "pooladm -s $POOLADMCONF"
			pooladm -s $POOLADMCONF
		fi
		echo "configure cpu pools:"
		echo ""
		cat $TMP
		echo ""
		echo "proceed? (y|[n]): \c"
		read ANS
		echo ""
		ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
		if [ _"$ANS" != _y ]
		then
			echo "not proceeding"
			Exit 1
		fi
		echo "pooladm -e"
		pooladm -e	# ensure active
		poolcfg -f $TMP # configure
		pooladm -n > $TMP.out 2>&1 # validate
		if [ ! $? -eq 0 ]
		then
			echo "ERROR: invalid pool configuration:"
			cat $TMP.out
			Exit 1
		fi
		rm $TMP.out
		pooladm -c	# instantiate config at $POOLADMCONF
		pooladm -s $POOLADMCONF		# rewrite config file
	fi
	rm $TMP
}

get_zfs()
{
	echo "global zone filesystems that the zone is to mount:"
	for i in /var/core /zone_common /export/home
	do
		if [ -d $i ]
		then
			echo "    mount global $i in this zone? (y|[n]): \c"
			read ANS
			ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
			if [ _"$ANS" = _y ]
			then
				cat >> $TMP <<!
add fs
set dir=$i
set special=$i
set type=lofs
!
				[ _"$i" = _/zone_common ] &&
				    echo "set options=[ro,nodevices]" >> $TMP
				echo end >> $TMP
			fi
		else
			echo "    no $i in global - ignored for zone"
		fi
	done
	cat <<!

enter any other filesystems that the zone needs as
    global mountpoint (e.g. /zones/$ZONE_NAME/fs/opt-home)
    zone mountpoint (e.g. /opt/home)
(dependent mounts must be supplied AFTER higher mounts
    e.g. /app/oracle would follow /app)

end list with a blank line
!
	while true
	do
		echo ""
		echo "global mountpoint [end of list]: \c"
		read GLOBAL_MP
		[ _"$GLOBAL_MP" = _ ] && break
		if [ ! -d "$GLOBAL_MP" ]
		then
			echo "<$GLOBAL_MP> not found"
			continue
		fi
		echo "zone mountpoint: \c"
		read ZONE_MP
		cat >> $TMP <<!
add fs
set dir=$ZONE_MP
set special=$GLOBAL_MP
set type=lofs
end
!
	done
}

make_sysidcfg()
{
	FSYSID=/etc/sysidcfg
	F=$ZONE_DIR/$ZONE_NAME/root$FSYSID

	if [ -s $F ]
	then
		while true
		do
			echo "$FSYSID already exists in zone image - overwrite? ([y]|n|!cmnd): \c"
			read ANS
			X=`echo "$ANS" | cut -c1`
			[ _"$X" != _! ] && break
			ANS=`echo "$ANS" | cut -c2-`
			sh -c "$ANS"
			echo "!"
		done
		ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
		[ _"$ANS" = _n ] && return
	fi
	cat > $F <<!
name_service=NONE
nfs4_domain=dynamic
!
if [ _"$IP_TYPE" = _n ]
then
	if [ _"$ZBRAND" = _n ]
	then
		echo "network_interface=NONE {hostname=$ZONE_NAME}" >> $F
	else
		# manual permits below line but still generates noise on s8/s9
		# and may (silently) ignore parts or all of sysidcfg file
		# (may need to fix manually)
		echo "network_interface=NONE" >> $F
		# below seems to set hostname OK s8/s9
		X=$ZONE_DIR/$ZONE_NAME/root/etc/nodename
		echo "$ZONE_NAME" > $X
		chmod 644 $X
	fi
else
	cat >> $F <<!
network_interface=primary
{
	hostname=$ZONE_NAME
!
	echo "${TAB}ip_address=$NET_IP" >> $F
	echo "${TAB}netmask=$NETMASK" >> $F
	[ _"$ZBRAND" != _8 ] && echo "${TAB}default_route=none" >> $F
	cat >> $F <<!
	protocol_ipv6=no
}
!
fi
# password below is sun123
cat >> $F <<!
root_password=veq/X7HHkTNK6
security_policy=NONE
terminal=vt100
timezone=Australia/NSW
timeserver=localhost
!

	# locales are a real pain...
	# must be in /usr/lib/locale of the installed system
	if [ _"$ZBRAND" != _n ]
	then
		ANS=C
	else
		echo ""
		echo "global locales:"
		locale
		echo ""
		echo "possible zone locales:"
		if [ _"$ZROOT" = _w ]
		then
			X=$ZONE_DIR/$ZONE_NAME/root/usr/lib/locale
		else
			X=/usr/lib/locale
		fi
		ls -l $X | grep "^d" | grep -v " common\$" | sed "s/.* /$TAB/"
		while true
		do
			echo "locale? [C]: \c"
			read ANS
			if [ _"$ANS" = _ ]
			then
				ANS=C
				break
			fi
			Y=`ls -ld $X/$ANS 2> /dev/null | cut -c1`
			[ _"$Y" = _d ] && break
			echo "not a valid locale - try again"
			echo ""
		done
	fi
	echo "system_locale=$ANS" >> $ZONE_DIR/$ZONE_NAME/root$FSYSID
}

if [ `zonename` != global ]
then
	echo "must be run in global zone"
	Exit 1
fi

if [ $# -gt 1 ]
then
	echo "Usage: $0 [config-file]"
	Exit 1
fi
FN="$1"
if [ _"$FN" != _ -a ! -r "$FN" ]
then
	echo "can't read $FN"
	FN=
fi

while true
do
	if [ _"$ZONE_DIR" = _ ]
	then
		get_zdir
		[ $? != 0 ] && continue
	fi
	if [ _"$ZONE_NAME" = _ ]
	then
		get_zname
		[ $? != 0 ] && continue
	fi
	if [ _"$IP_TYPE" = _ ]
	then
		get_zIPtype
	fi
	if [ _"$IP_TYPE" != _n ]
	then
		if [ _"$NET_IP" = _ ]
		then
			get_zIP
			[ $? != 0 ] && continue
		fi
		if [ _"$NET_PHYSICAL" = _ ]
		then
			get_zif
			[ $? != 0 ] && continue
		fi
	fi
	if [ _"$ZBRAND" = _ ]
	then
		get_zbrand
		[ $? != 0 ] && continue
	fi
	if [ _"$IMAGEF" = _ ]
	then
		get_zimagef
		[ $? != 0 ] && continue
	fi
	if [ _"$ZROOT" = _ ]
	then
		get_zroottype
	fi
	if [ _"$CPUS" = _ ]
	then
		get_zcpucap
		[ $? != 0 ] && continue
	fi
	if [ _"$MEM_CAP" = _ ]
	then
		get_zmemcap
		[ $? != 0 ] && continue
	fi
	if [  _"$MEM_CAP" != _ -a _"$SWAP_CAP" = _ ]
	then
		get_zswapcap
		[ $? != 0 ] && continue
	fi
	echo ""
	echo "zone parent directory: $ZONE_DIR"
	echo "zone name: $ZONE_NAME"
	echo "ip-type: \c"
	if [ _"$IP_TYPE" = _s ]
	then
		echo "shared"
	elif [ _"$IP_TYPE" = _e ]
	then
		echo "exclusive"
	else
		echo "none"
	fi
	if [ _"$IP_TYPE" != _n ]
	then
		echo "IP: $NET_IP"
		echo "physical interface: $NET_PHYSICAL"
	fi
	if [ _"$ZBRAND" = _n ]
	then
		echo "native\c"
		[ _"$IMAGEF" != _! ] && echo " (image $IMAGEF)\c"
		echo ""
	else
		echo "branded solaris $ZBRAND (image $IMAGEF)"
	fi
	[ _"$ZROOT" = _w ] && echo "whole-root" || echo "sparse-root"
	[ _"$CPU_CAP" != _ ] && echo "cpu cap: $CPU_CAP"
	if [ _"$PSET_NAME" != _ ]
	then
		if [ _"$MAKE_PSET" != _ ]
		then
			echo "make pset $PSET_NAME (cpu thread cap: $NUM_CPUS)"
		else
			echo "use pset $PSET_NAME"
		fi
	fi
	if [ _"$POOL_NAME" != _ ]
	then
		if [ _"$MAKE_POOL" != _ ]
		then
			echo "make pool $POOL_NAME"
		else
			echo "use pool $POOL_NAME"
		fi
	fi
	[  _"$MEM_CAP" != _ ] && echo "memory cap: $MEM_CAP"
	[ _"$SWAP_CAP" != _ ] && echo "swap cap: $SWAP_CAP"
	echo ""
	echo "confirm (y|[n]): \c"
	read ANS
	echo ""
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	[ _"$ANS" = _y ] && break
	ZONE_DIR=
	ZONE_NAME=
	IP_TYPE=
	NET_IP=
	NET_PHYSICAL=
	ZBRAND=
	IMAGEF=
	ZROOT=
	CPUS=
	CPU_CAP=
	PSET_NAME=
	POOL_NAME=
	MEM_CAP=
	SWAP_CAP=
done

# zone config
if [ _"$ZBRAND" != _n ]
then
	echo "create -t SUNWsolaris$ZBRAND" > $TMP
elif [ _"$ZROOT" = _w ]
then
	echo "create -b" > $TMP
else
	echo "create" > $TMP
fi
cat >> $TMP <<!
set zonepath=$ZONE_DIR/$ZONE_NAME
set autoboot=false
set bootargs="-m verbose"
!
if [ _"$CPU_CAP" != _ ]
then
	cat >> $TMP <<!
add capped-cpu
set ncpus=$CPU_CAP
end
!
fi
if [ _"$POOL_NAME" != _ ]
then
	echo "set pool=$POOL_NAME" >> $TMP
fi
[ _"$IP_TYPE" = _e ] && echo "set ip-type=exclusive" >> $TMP

get_zfs

# while it doesn't matter, "add net" customarily follows "add fs"
if [ _"$IP_TYPE" != _n ]
then
	echo "add net" >> $TMP
	[ _"$IP_TYPE" = _s ] && echo "set address=$NET_IP" >> $TMP
	cat >> $TMP <<!
set physical=$NET_PHYSICAL
end
!
fi

if [ _"$MEM_CAP" != _ ]
then
	cat >> $TMP <<!
add capped-memory
set physical=${MEM_CAP}m
!
	if [ _"$SWAP_CAP" != _ ]
	then
		echo "set swap=${SWAP_CAP}m" >> $TMP
	fi
	echo "end" >> $TMP
fi
cat >> $TMP <<!
verify
commit
!
echo ""
echo "configure zone:"
echo ""
cat $TMP
while true
do
	echo ""
	echo "proceed? (y|[n]|e): \c"
	read ANS
	echo ""
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	[ _"$ANS" = _y ] && break
	if [ _"$ANS" != _e ]
	then
		echo "not proceeding"
		Exit 1
	fi
	[ _"$EDITOR" = _ ] && EDITOR=/bin/ed
	$EDITOR $TMP
done

if [ ! -d $ZONE_DIR/$ZONE_NAME ]
then
	mkdir -p $ZONE_DIR/$ZONE_NAME
fi
chmod 700 $ZONE_DIR/$ZONE_NAME || Exit 1

# cpu threads
[ _"$MAKE_PSET" != _ -o _"$MAKE_POOL" != _ ] && make_cpupool

zonecfg -z $ZONE_NAME -f $TMP
[ $? != 0 ] && Exit 1
if [ _"$IMAGEF" != _! ]
then
	CMD="zoneadm -z $ZONE_NAME install -$IMAGEFFLAG -a $IMAGEF"
else
	CMD="zoneadm -z $ZONE_NAME install"
fi
echo "empty zone created - about to install using"
echo "$TAB$CMD"
echo ""
echo "proceed? ([y]|n): \c"
read ANS
echo ""
ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
if [ _"$ANS" = _n ]
then
	echo "not proceeding - install/attach and boot manually"
	Exit 1
fi
echo "$CMD"
$CMD
[ $? != 0 ] && Exit 1

make_sysidcfg

while true
do
	echo "boot $ZONE_NAME? (y|[n]|!cmnd): \c"
	read ANS
	X=`echo "$ANS" | cut -c1`
	[ _"$X" != _! ] && break
	ANS=`echo "$ANS" | cut -c2-`
	sh -c "$ANS"
	echo "!"
done
ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
if [ _"$ANS" != _y ]
then
	cat <<!
to boot this zone later use:
zoneadm -z $ZONE_NAME boot
zlogin -C $ZONE_NAME # root pwd is sun123; <CR>~. to disconnect
!
	Exit 0
fi
CMD="zoneadm -z $ZONE_NAME boot"
echo "$CMD"
$CMD
[ $? != 0 ] && Exit 1
cat <<!

connecting to zone to monitor boot messages
root pwd is sun123
enter <CR>~. to disconnect

!
CMD="zlogin -C $ZONE_NAME"
echo "$CMD"
$CMD
Exit 0

#!/bin/sh
# script run after a system (or zone) boots as
#
#	sh /etc/rc3.d/S99uvh start
#
#   which create an at-job to run 2 minutes later as
#
#	sh /etc/rc3.d/S99uvh boot
#
#   to
#     alert root (by mail) that a reboot has occurred
#	mail includes from (reboot-20) lines of the messages file
#	check for crash dump in /var/crash/{hostname}
#	maintain rotating reboot log file
#     unplumb USB NIC
#     set interzone network restriction
#     under the control of a configuration file (LOCAL_CF below):
#	plumb global interfaces (so zones can start)
#	  not plumbed:
#	    not boot: whinge
#	    boot: if aggregate known plumb interface (IP 0.0.0.0 if none given)
#	check NFS mounts are done (not done at boot time)
#	  check known to vfstab and marked "yes"
#	  not mounted: whinge (do not mount to avoid any race)
#	take ownership of metasets
#	  check metaset known to this host
#	  not owned by this host:
#	    not boot: whinge
#	    boot: take ownership
#	mount SAN LUNs
#	  check known to vfstab, marked "no"
#	  not mounted:
#	    not boot: whinge
#	    boot: if NFS unshare; mount; if NFS share
#	boot zones
#	  check zone is known
#	  not running:
#	    not boot: whinge
#	    boot: if zonepath/root exists and autoboot is false then boot zone
#	  check for zones not in master file
#	  run UVH_Z_CONFCHK against each zone
#	check zone loopback mounts (not done at boot time)
#	  not mounted: whinge (do not mount to avoid any race)
#
# can also be run from cron or manually (as a check) as
#
#	/etc/rc3.d/S99uvh [-q][-v]
#
#   to check the above items (and that the following 4 files are up to date)

MASTER_SCRIPT=/UVH/bin/uvh-boot.sh	# source-of-truth
MASTER_CF=/UVH/etc/uvh-master		# source-of-truth
LOCAL_SCRIPT=/etc/rc3.d/S99uvh
LOCAL_CF=/usr/local/etc/uvh-master	# local disk, not NFS-mount

# master-copy is at MASTER_SCRIPT (above) and distributed using uvh-update.sh

VFSTAB=/etc/vfstab
DFSTAB=/etc/dfs/dfstab
UVH_Z_CONFCHK=/UVH/bin/uvh-zone-confchk.sh

HN=`hostname`
GZ=`zonename | grep "^global\$"`
STATUS=0

TAB='	'	# care - tab (don't cut and paste)
TMP=/tmp/uvh.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3


# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

# echo message and (if boot-time) append to root-mail
echom()
{
	echo "$@"
	[ _"$BOOTLOG" != _ ] && echo "$@" >> $TMP.m
}

if [ _"$1" = _start ]	# called by system on boot
then
	# postpone activity to allow boot to settle down (many races)
	echo "sh $LOCAL_SCRIPT boot" | at now + 2 minutes
	Exit 0
fi

if [ _"$1" = _boot ]	# called from at-job 2m after system boot
then
	MESSAGES=/var/adm/messages
	BOOTLOG=/var/adm/reboot
	BOOTSTR="SunOS Release "

	[ -f $BOOTLOG.1 ] && mv $BOOTLOG.1 $BOOTLOG.2
	[ -f $BOOTLOG.0 ] && mv $BOOTLOG.0 $BOOTLOG.1
	[ -f $BOOTLOG ] && mv $BOOTLOG $BOOTLOG.0
	exec > $BOOTLOG 2>&1

	date | tee $TMP.m
	if [ _"$GZ" != _ ]
	then
		X=/var/crash/$HN
		if [ -d $X ]
		then
			X=`ls $X`
			if [ _"$X" != _ ]
			then
				echom "$X:"
				ls -l $X | tee -a $TMP.m
				echom ""
			fi
		fi
		LINES=20
		X=`grep -n "$BOOTSTR" $MESSAGES | tail -1 | cut -f1 -d:`
		if [ _"$X" = _ ]
		then
			echom "can't find reboot start"
		else
			cp /dev/null $TMP.a
			if [ $X -gt 1 ]
			then
				Y=`expr $X - 1`
				if [ $X -gt $LINES ]
				then
					X=`expr $X - $LINES`
					echo " ..." | tee -a $TMP.a
				else
					X=1
				fi
				sed -n -e "$X,${Y}p" $MESSAGES | tee -a $TMP.a
				echo "" | tee -a $TMP.a
				echo \-"---- reboot -----" | tee -a $TMP.a
				echo "" | tee -a $TMP.a
				X=`expr $Y + 1`
			fi
			sed -n -e "$X,\$p" $MESSAGES | tee -a $TMP.a
			if [ ! -s $TMP.a ]
			then
				echom "nothing found in $MESSAGES to attach"
				rm $TMP.a
			fi
			echom ""
		fi
	fi
else
	[ _"$1" = _-q ] && QUIET=true
	[ _"$1" = _-v ] && VERBOSE=true
	# ad-hoc check - start by checking files are up to date
	# (not as part of boot as NFS may not be available so don't hang)
	[ _"$VERBOSE" != _ ] && echo "check local copies against masters"
	if [ ! -s $MASTER_SCRIPT ]
	then
		echo "can't find $MASTER_SCRIPT"
		cp /dev/null $TMP.e
	elif [ ! -s $LOCAL_SCRIPT ]
	then
		echo "can't find $LOCAL_SCRIPT"
		cp /dev/null $TMP.e
	else
		cmp -s $MASTER_SCRIPT $LOCAL_SCRIPT
		if [ $? != 0 ]
		then
			echo "$LOCAL_SCRIPT != $MASTER_SCRIPT"
			cp /dev/null $TMP.e
		fi
	fi
	if [ ! -s $MASTER_CF ]
	then
		echo "can't find $MASTER_CF"
		cp /dev/null $TMP.e
	elif [ ! -s $LOCAL_CF ]
	then
		echo "can't find $LOCAL_CF"
		cp /dev/null $TMP.e
	else
		cmp -s $MASTER_CF $LOCAL_CF
		if [ $? != 0 ]
		then
			echo "$LOCAL_CF != $MASTER_CF"
			cp /dev/null $TMP.e
		fi
	fi
	if [ -f $TMP.e ]
	then
		STATUS=1
	elif [ _"$QUIET" = _ ]
	then
		echo "local copies OK"
	fi
	rm -f $TMP.e
fi

# boot (output redirected to BOOTLOG) or ad-hoc check continue below
if [ _"$GZ" != _ ]	# only in global zone
then
	# lose silly USB NIC
	X=usbecm0
	[ _"$VERBOSE" != _ ] && echo "check for USB NIC $X"
	Y=`ifconfig $X 2> /dev/null`
	if [ _"$Y" != _ ]
	then
		if [ _"$BOOTLOG" = _ ]
		then
			echo "NIC $X has reappeared"
			STATUS=1
		else
			CMD="ifconfig $X unplumb"
			echo $CMD | tee -a $TMP.m
			$CMD 2>&1 | tee -a $TMP.m
		fi
	elif [ _"$QUIET" = _ ]
	then
		echo "$X OK"
	fi

	# force interzone traffic through external router firewalls
	# (in practice evidence suggests this is broken)
	X=ip_restrict_interzone_loopback
	[ _"$VERBOSE" != _ ] && echo "check for $X"
	Y=`ndd /dev/ip $X`
	if [ _"$Y" = _0 ]
	then
		if [ _"$BOOTLOG" = _ ]
		then
			echo "$X not set"
			STATUS=1
		else
			CMD="ndd -set /dev/ip $X 1"
			echo $CMD | tee -a $TMP.m
			$CMD 2>&1 | tee -a $TMP.m
		fi
	elif [ _"$QUIET" = _ ]
	then
		echo "$X OK"
	fi

	# pre-digest configuration file for ease of following matches
	[ ! -s "$LOCAL_CF" ] && LOCAL_CF=/dev/null
	grep "^$HN[ $TAB]" $LOCAL_CF |
	    sed "s/#.*//" |
	    sed -e "s/[ $TAB][ $TAB]*/ /g" -e "s/ \$//" |
	    sed "s/$HN //" > $TMP.cf

	# plumb interfaces so zones start
	[ _"$VERBOSE" != _ ] && echo "check interfaces"
	grep "^plumb " $TMP.cf | while read LINE
	do
		# LINE is interface [IP netmask]
		LINE=`expr "$LINE" : "[^ ]* \(.*\)"`
		if [ _"$LINE" = _ ]
		then
			echom "$LOCAL_CF: error in $HN plumb"
			cp /dev/null $TMP.e
			continue
		fi
		[ _"$VERBOSE" != _ ] && echo "$LINE"
		IF_NAME=`expr "$LINE" :  "\([^ ]*\)"`	# interface
		LINE=`expr "$LINE" : "[^ ]* \(.*\)"`
		IF_IP=`expr "$LINE" : "\([^ ]*\)"`	# [IP]
		LINE=`expr "$LINE" : "[^ ]* \(.*\)"`
		if [ _"$IF_IP" = _ ]
		then
			IF_MASK=
		else
			IF_MASK=`expr "$LINE" : "\([^ ]*\)"`	# [mask]
			LINE=`expr "$LINE" : "[^ ]* \(.*\)"`
			if [ _"$LINE" != _ -o _"$IF_MASK" = _ ]
			then
				echom "$LOCAL_CF: $IF_NAME: junk on line"
				cp /dev/null $TMP.e
				continue
			fi
		fi
		X=`ifconfig "$IF_NAME" 2> /dev/null`
		if [ _"$X" != _ ]
		then
			case "$IF_MASK"
			in
			255.255.255.240) IF_MASK=fffffff0 ;;
			255.255.255.224) IF_MASK=ffffffe0 ;;
			255.255.255.192) IF_MASK=ffffffc0 ;;
			255.255.255.128) IF_MASK=ffffff80 ;;
			255.255.255.0)   IF_MASK=ffffff00 ;;
			255.255.254.0)   IF_MASK=fffffe00 ;;
			255.255.252.0)   IF_MASK=fffffc00 ;;
			255.255.248.0)   IF_MASK=fffff800 ;;
			255.255.240.0)   IF_MASK=fffff000 ;;
			'')		;;
			*)		echom "$LOCAL_CF: $IF_NAME: invalid mask"
					cp /dev/null $TMP.e
					continue
					;;
			esac
			Y=`expr "$X" : ".*<\(UP\),"`
			if [ _"$IF_IP" != _ -a _"$Y" = _ ]
			then
				echom "$LOCAL_CF: $IF_NAME not up"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`expr "$X" : ".*inet \($IF_IP\) "`
			if [ _"$IF_IP" != _ -a _"$Y" = _ ]
			then
				echom "$LOCAL_CF: $IF_NAME bad IP"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`expr "$X" : ".* netmask \($IF_MASK\) "`
			if [ _"$IF_MASK" != _ -a _"$Y" = _ ]
			then
				echom "$LOCAL_CF: $IF_NAME bad netmask"
				cp /dev/null $TMP.e
			fi
			continue
		fi
		X=`expr "$IF_NAME" : "^aggr[0-9][0-9]*\([0-9][0-9][0-9]\)\$"`
		if [ _"$X" = _ ]
		then
			echom "interface $IF_NAME bad (no key)"
			cp /dev/null $TMP.e
			continue
		fi
		if [ _"$BOOTLOG" = _ ]
		then
			echom "interface $IF_NAME not plumbed"
			cp /dev/null $TMP.e
			continue
		fi
		X=`expr "$X" : "0*\(.*\)"`	# strip leading zeros
		if [ _"$X" = _ ]
		then
			echom "interface $IF_NAME invalid key (0)"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`dladm show-aggr "$X" 2> /dev/null | grep "^key: $X "`
		if [ _"$Y" = _ ]
		then
			echom "interface $IF_NAME cannot be plumbed (key $X does not exist)"
			cp /dev/null $TMP.e
			continue
		fi
		CMD="ifconfig $IF_NAME plumb"
		[ _"$IF_IP" != _ ] && CMD="$CMD $IF_IP $IF_MASK UP"
		echom "$CMD"
		$CMD 2>&1 | tee -a $TMP.m
	done
	if [ -f $TMP.e ]
	then
		STATUS=2
	elif [ _"$QUIET" = _ -a _"$BOOTLOG" = _ ]
	then
		echo "interfaces OK"
	fi
	rm -f $TMP.e

	# NFS mounts (skip at boot-time)
	if [ _"$BOOTLOG" = _ ]
	then
		[ _"$VERBOSE" != _ ] && echo "check NFS mounts"
		grep "^nfs " $TMP.cf | while read LINE
		do
			X=`expr "$LINE" : "[^ ]* \(.*\)"`
			if [ _"$X" = _ ]
			then
				echo "$LOCAL_CF: error in $HN nfs"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`grep "[ $TAB]$X[ $TAB]" $VFSTAB`
			if [ _"$Y" = _ ]
			then
				echo "nfs-mount $X not in $VFSTAB"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`expr "$Y" : ".*[ $TAB]\(yes\)[ $TAB]"`
			if [ _"$Y" = _ ]
			then
				echo "nfs-mount $X not marked yes in $VFSTAB"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`mount | grep "^$X on "`
			[ _"$VERBOSE" != _ ] && echo "$Y"
			[ _"$Y" != _ ] && continue
			echo "nfs-mount $X missing"
			cp /dev/null $TMP.e
		done
		if [ -f $TMP.e ]
		then
			STATUS=2
		elif [ _"$QUIET" = _ ]
		then
			echo "NFS mounts OK"
		fi
		rm -f $TMP.e
	fi

	# metasets
	[ _"$VERBOSE" != _ ] && echo "check metasets"
	grep "^metaset " $TMP.cf | while read LINE
	do
		X=`expr "$LINE" : "[^ ]* \(.*\)"`
		if [ _"$X" = _ ]
		then
			echom "$LOCAL_CF: error in $HN metaset"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`metaset -s "$X" 2> /dev/null | egrep " $HN | $HN\$"`
		[ _"$VERBOSE" != _ ] && echo "$X: $Y"
		if [ _"$Y" = _ ]
		then
			echom "metaset $X not found"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`expr "$Y" : ".* \(Yes\)"`
		[ _"$Y" != _ ] && continue
		if [ _"$BOOTLOG" = _ ]
		then
			echo "metaset $X not owned"
			cp /dev/null $TMP.e
			continue
		fi
		CMD="metaset -s $X -t"
		echom "$CMD"
		$CMD 2>&1 | tee -a $TMP.m
	done
	if [ -f $TMP.e ]
	then
		STATUS=2
	elif [ _"$QUIET" = _ -a _"$BOOTLOG" = _ ]
	then
		echo "metasets OK"
	fi
	rm -f $TMP.e

	# mounts
	[ _"$VERBOSE" != _ ] && echo "check mounts"
	grep "^mount " $TMP.cf | while read LINE
	do
		X=`expr "$LINE" : "[^ ]* \(.*\)"`
		if [ _"$X" = _ ]
		then
			echom "$LOCAL_CF: error in $HN mount"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`grep "[ $TAB]$X[ $TAB]" $VFSTAB`
		if [ _"$Y" = _ ]
		then
			echom "$X not in $VFSTAB"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`expr "$Y" : ".*[ $TAB]\(no\)[ $TAB]"`
		if [ _"$Y" = _ ]
		then
			echom "$X not marked no in $VFSTAB"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`mount | grep "^$X on "`
		[ _"$VERBOSE" != _ ] && echo "$Y"
		[ _"$Y" != _ ] && continue
		if [ _"$BOOTLOG" = _ ]
		then
			echo "$X not mounted"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`grep . $DFSTAB | grep -v "^#" | grep "[ $TAB]$X\$"`
		if [ _"$Y" != _ ]
		then
			CMD="unshare $X"
			echom "$CMD"
			$CMD 2>&1 | tee -a $TMP.m
		fi
		CMD="mount $X"
		echom "$CMD"
		$CMD 2>&1 | tee -a $TMP.m
		if [ _"$Y" != _ ]
		then
			CMD="shareall"
			echom "$CMD"
			$CMD 2>&1 | tee -a $TMP.m
		fi
	done
	if [ -f $TMP.e ]
	then
		STATUS=2
	elif [ _"$QUIET" = _ -a _"$BOOTLOG" = _ ]
	then
		echo "mounts OK"
	fi
	rm -f $TMP.e

	# zones
	[ _"$VERBOSE" != _ ] && echo "check zones"
	cp /dev/null $TMP.z
	grep "^zone " $TMP.cf | while read LINE
	do
		X=`expr "$LINE" : "[^ ]* \(.*\)"`
		if [ _"$X" = _ ]
		then
			echom "$LOCAL_CF: error in $HN zone"
			cp /dev/null $TMP.e
			continue
		fi
		echo "$X" >> $TMP.z	# used below to detect extra zones
		Y=`zoneadm -z $X list -v 2> /dev/null | tail -1`
		[ _"$VERBOSE" != _ ] && echo "$Y"
		if [ _"$Y" = _ ]
		then
			echom "zone $X not found"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`expr "$Y" : ".* $X  *\([^ ]*\) .*"`
		[ _"$Y" = _running ] && continue
		if [ _"$BOOTLOG" = _ ]
		then
			echo "zone $X not running (state is $Y)"
			cp /dev/null $TMP.e
			continue
		fi
		Y=`zonecfg -z $X info | grep "zonepath:" | cut -f2 -d' '`
		if [ _"$Y" = _ ]
		then
			echom "zone $X no zonepath"
			continue
		fi
		if [ ! -d "$Y/root" ]
		then
			echom "zone $X no root filesystem"
			continue
		fi
		Y=`zonecfg -z $X info | grep "autoboot:"`
		Y=`expr "$Y" : ".*\(false\)"`
		if [ _"$Y" = _ ]
		then
			echom "zone $X autoboot not false"
			continue
		fi
		CMD="zoneadm -z $X boot"
		echom "$CMD"
		$CMD 2>&1 | tee -a $TMP.m
	done
	if [ _"$BOOTLOG" = _ ]
	then
		zoneadm list -c | grep -v "^global\$" | sort > $TMP.zl
		[ -s $TMP.z ] && sort $TMP.z -o $TMP.z
		for i in `comm -13 $TMP.z $TMP.zl`
		do
			echo "zone $i configured but not in $LOCAL_CF"
			cp /dev/null $TMP.e
		done
		if [ ! -x $UVH_Z_CONFCHK ]
		then
			echo "can't find $UVH_Z_CONFCHK"
		else
			for i in `comm -12 $TMP.z $TMP.zl`
			do
				sh $UVH_Z_CONFCHK $i > $TMP.co 2>&1
				if [ -s $TMP.co ]
				then
					echo "$UVH_Z_CONFCHK $i: fails"
					cp /dev/null $TMP.e
				fi
				rm $TMP.co
			done
		fi
	fi
	if [ -f $TMP.e ]
	then
		STATUS=2
	elif [ _"$QUIET" = _ -a _"$BOOTLOG" = _ ]
	then
		echo "zones OK"
	fi
	rm -f $TMP.e $TMP.z $TMP.zl $TMP.co

	# loopback mounts
	if [ _"$BOOTLOG" = _ ]
	then
		[ _"$VERBOSE" != _ ] && echo "check loopbacks"
		grep "^lofs " $TMP.cf | while read LINE
		do
			X=`expr "$LINE" : "[^ ]* \(.*\)"`
			if [ _"$X" = _ ]
			then
				echo "$LOCAL_CF: error in $HN lofs"
				cp /dev/null $TMP.e
				continue
			fi
			Y=`mount | grep "^$X on "`
			[ _"$VERBOSE" != _ ] && echo "$Y"
			[ _"$Y" != _ ] && continue
			echo "$X not loopback-mounted"
			cp /dev/null $TMP.e
		done
		if [ -f $TMP.e ]
		then
			STATUS=2
		elif [ _"$QUIET" = _ ]
		then
			echo "loopbacks OK"
		fi
		rm -f $TMP.e
	fi
fi

if [ _"$BOOTLOG" != _ ]
then
	# create mail and attachments for boot-alert to root
	cat > $TMP <<!
Subject: reboot_$HN $DATE
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=kev_was_here

This is a multi-part message in MIME format.
Since your mail reader does not understand this format,
some or all of this message may not be legible.

--kev_was_here
Content-Type: text/plain

(best if any mail-reader message reformatting is disabled)

!
	cat $TMP.m >> $TMP
	if [ -s $TMP.a ]
	then
		cat >> $TMP <<!

$MESSAGES extract attached
--kev_was_here
Content-Type: text/plain; name=messages-extract.txt

!
		cat $TMP.a >> $TMP
	fi
	rm -f $TMP.a
	cat >> $TMP <<!
--kev_was_here--
!
	sendmail root < $TMP
	rm $TMP
elif [ $STATUS -gt 1 ]
then
	cat <<!

required configuration items above are stored in $LOCAL_CF
which is a local copy of the master file $MASTER_CF
!
fi

Exit

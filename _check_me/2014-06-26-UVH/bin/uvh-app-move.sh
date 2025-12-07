#!/bin/sh

# disable application group (if found on a zone on a host in HLIST below) and
#   if another zone on this host is named, migrate the application group to it
#
# runs by default in "safe-mode" - use "-x" to execute
#
# both remote and local host must have vfstab entries and access to /UVH
# local host must also have access to the relevant metaset
#
# TO_DO: invoke specified application group shutdown/startup script
#
# assumptions:
#   application group LUNs are mounted filesystem from a dedicated metaset
#   such filesystems and any associated loopback mounts are mount-at-boot "no"
#	in vfstab

TMP=/tmp/uvh.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

TAB='	'	# care - tab (don't cut and paste)

HLIST="auszvuvh001 auszvuvh002 auszvuvh004 auszvuvh005"
HLIST="auszvuvh002 auszvuvh005"	# DEBUG

THIS_HOST=`hostname | cut -d. -f1`
VFSTAB=/etc/vfstab
STATUS=0
UVH_APP_CHK=/UVH/bin/uvh-app-confchk.sh

umask 022

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

if [ _"$1" = _-x ]
then
	EXEC=true
	shift
fi
if [ $# != 1 -a $# != 2 ]
then
	echo "usage: $0 [-x] <app-name> [<zone-name>]"
	Exit 1
fi
APP_NAME=$1
ZONE_NAME=$2

if [ _"$EXEC" = _ ]
then
	echo ""
	echo "running in safe-mode (use -x to make changes)"
	echo ""
fi

err()
{
	echo "$1"
	echo ""
	echo "any actions that may have been listed above have been executed"
	echo "fix the problem indicated and run this script again to continue"
	Exit 1
}

Start_App()
{
	START_X=`grep "^start " $TMP.master | cut -d' ' -f2-`
	if [ _"$START_X" != _ ]
	then
		[ _"$EXEC" = _ ] && START_X="echo $START_X"
		$START_X
	fi
}

Stop_App()
{
	PHYSHOST="$1"

	[ _"$STOPF" != _ ] && return
	STOPF=true
	STOP_X=`grep "^stop " $TMP.master | cut -d' ' -f2-`
	if [ _"$STOP_X" != _ ]
	then
		[ _"$PHYSHOST" != _"$THIS_HOST" ] && STOP_X="ssh $PHYSHOST $STOP_X"
		[ _"$EXEC" = _ ] && STOP_X="echo $STOP_X"
		$STOP_X
	fi
}

Umount()
{
	H="$1"
	D="$2"

	Stop_App $H
	CMD="umount $D"
	[ _"$H" != _"$THIS_HOST" ] && CMD="ssh $H $CMD"
	echo "$CMD"
	[ _"$EXEC" = _ ] && return
	$CMD
	CMD="mount"
	[ _"$H" != _"$THIS_HOST" ] && CMD="ssh $H $CMD"
	X=`$CMD | grep "^$D"`
	[ _"$X" = _ ] && return
	# stupid HP monitoring tool likes to sit on mountpoints, preventing
	#   them unmounting - restarting it makes it go away
	echo "failed to unmount $D on $H - restarting system monitor"
	CMD="sh /etc/init.d/lw_agt restart"
	[ _"$H" != _"$THIS_HOST" ] && CMD="ssh $H $CMD"
	echo "$CMD"
	[ _"$EXEC" != _ ] && $CMD
	CMD="umount $D"
	[ _"$H" != _"$THIS_HOST" ] && CMD="ssh $H $CMD"
	echo "$CMD"
	[ _"$EXEC" != _ ] && $CMD
	CMD="mount"
	[ _"$H" != _"$THIS_HOST" ] && CMD="ssh $H $CMD"
	X=`$CMD | grep "^$D"`
	[ _"$X" != _ ] && err "failed to unmount $D on $H"	# no return
}

netfiddle()
{
	F=$1

	grep . $F | sed "s/[ $TAB][ $TAB]*/ /g" > $TMP.nf
	ed - $TMP.nf <<!
g/: flags=.*</s//</
g/>.*/s//>/
g/<.*>/s///
g/ netmask.*/s///
g/ groupname /d
g/ zone /d
g/ ether /d
g/^ /-,.j
g/^lo/d
w
!
	[ $? -eq 0 ] && cp $TMP.nf $F && rm $TMP.nf
}

if [ _"$ZONE_NAME" != _ ]
then
	X=`zoneadm -z $ZONE_NAME list -p 2> /dev/null | cut -d: -f3,7`
	Y=`expr "$X" : "\(running\):.*"`
	[ _"$Y" = _ ] && err "$ZONE_NAME is not running on this host"
	EXCL=`expr "$X" : ".*:\(excl\)\$"`
fi

MASTER=/UVH/etc/uvh-master
[ ! -r "$MASTER" ] && err "$MASTER not found"	# no return
# pre-digest $MASTER for ease of subsequent tests
grep "^$APP_NAME[ $TAB]" $MASTER |
    sed -e "s/#.*//" -e "s/[ $TAB][ $TAB]*/ /g" -e "s/ \$//" |
    cut -d' ' -f2- > $TMP.master
[ ! -s $TMP.master ] && err "$APP_NAME not found in $MASTER"	# no return
METASET=`grep "^metaset " $TMP.master | tail -1 | cut -d' ' -f2`
[ _"$METASET" = _ ] && err "can't find metaset for $APP_NAME in $MASTER"	# no return

# pre-digest $VFSTAB for ease of subsequent tests
grep -v "^#" $VFSTAB | sed "s/[ $TAB][ $TAB]*/ /g" |
    egrep " ufs | lofs " > $TMP.fs
if [ _"$ZONE_NAME" != _ ]
then
	for i in `grep "^mount " $TMP.master | cut -d' ' -f2 | sed "s/\\$ZONE_NAME/$ZONE_NAME/"`
	do
		X=`grep " $i ufs .* no " $TMP.fs`
		[ _"$X" = _ ] && err "ufs mountpoint $i not in $VFSTAB"
	done
	for i in `grep "^lofs " $TMP.master | cut -d' ' -f2 | sed "s/\\$ZONE_NAME/$ZONE_NAME/"`
	do
		X=`grep " $i lofs .* no " $TMP.fs`
		[ _"$X" = _ ] && err "loopback mountpoint $i not in $VFSTAB"
	done
	rm $TMP.fs
	if [ _"$EXEC" != _ ]
	then
		echo "application group $APP_NAME will be moved to zone $ZONE_NAME"
		echo "  on this host ($THIS_HOST)"
	fi
else
	[ _"$EXEC" != _ ] && echo "application group $APP_NAME will be disabled (if found)"
fi

if [ _"$EXEC" != _ ]
then
	echo "confirm: (y|[n]) \c"
	read ANS
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	if [ _"$ANS" != _y ]
	then
		echo "exiting"
		Exit 0
	fi
fi
STOPF=
for i in $HLIST
do
	[ _"$i" = _"$THIS_HOST" -a _"$ZONE_NAME" != _ ] && continue
	echo "inspect $i:"
	CMD="zoneadm list -p"
	[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
	$CMD | grep '[^:]*:[^:]*:running:' | grep -v :global: | cut -d: -f2,7 > $TMP.z
	for j in `cat $TMP.z`
	do
		X_ZN=`echo "$j" | cut -d: -f1`
		X_EXCL=`echo "$j" | cut -d: -f2-`
		CMD="zlogin $X_ZN ifconfig -a"
		[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
		$CMD > $TMP.if
		netfiddle $TMP.if
		for k in `grep "^plumb " $TMP.master | cut -d' ' -f3,5`
		do
			K_IP=`echo "$k" | cut -d' ' -f1`
			K_ZN=`echo "$k" | cut -d' ' -f2`
			# cut returns f1 if there is no f2 (sigh)
			[ _"$K_IP $K_ZN" != _"$k" ] && K_ZN=
			[ _"$K_ZN" != _ -a _"$K_ZN" != _"$X_ZN" ] && continue
			X=`grep " $K_IP\$" $TMP.if`
			if [ _"$X" != _ ]
			then
				Stop_App $i
				X=`echo "$X" | cut -d' ' -f1`
				if [ _"$X_EXCL" = _excl ]
				then
					CMD="zlogin $X_ZN ifconfig $X unplumb"
					[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
				else
					CMD="ifconfig $X unplumb"
					[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
				fi
				echo "$CMD"
				[ _"$EXEC" != _ ] && $CMD
			fi
		done
		rm $TMP.if
	done
	CMD="mount"
	[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
	$CMD > $TMP.m
	CMD="zoneadm list"
	[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
	$CMD | grep -v global > $TMP.z
	for j in `grep "^lofs " $TMP.master | cut -d' ' -f2`
	do
		for k in `cat $TMP.z`
		do
			X_J=`echo "$j" | sed "s/\\$ZONE_NAME/$k/"`
			X=`grep "^$X_J " $TMP.m`
			[ _"$X" != _ ] && Umount $i $X_J
			if [ _"$i" != _"$THIS_HOST" ]
			then
				X=`ssh $i "ls -d $X_J 2> /dev/null"`
			else
				X=`ls -d $X_J 2> /dev/null`
			fi
			if [ _"$X" != _ ]
			then
				CMD="rmdir $X_J"
				[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
				echo "$CMD"
				[ _"$EXEC" != _ ] && $CMD
			fi
		done
	done
	for j in `grep "^mount " $TMP.master | cut -d' ' -f2`
	do
		for k in `cat $TMP.z`
		do
			X_J=`echo "$j" | sed "s/\\$ZONE_NAME/$k/"`
			X=`grep "^$X_J " $TMP.m`
			[ _"$X" != _ ] && Umount $i $X_J
			if [ _"$i" != _"$THIS_HOST" ]
			then
				X=`ssh $i "ls -d $X_J 2> /dev/null"`
			else
				X=`ls -d $X_J 2> /dev/null`
			fi
			if [ _"$X" != _ ]
			then
				CMD="rmdir $X_J"
				[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
				echo "$CMD"
				[ _"$EXEC" != _ ] && $CMD
			fi
		done
	done
	rm $TMP.m
	if [ _"$i" != _"$THIS_HOST" ]
	then
		X=`ssh $i "metaset -s $METASET 2> /dev/null" | grep " $i[ $TAB][ $TAB]*Yes"`
	else
		X=`metaset -s $METASET 2> /dev/null | grep " $i[ $TAB][ $TAB]*Yes"`
	fi
	if [ _"$X" != _ ]
	then
		CMD="metaset -s $METASET -r"
		[ _"$i" != _"$THIS_HOST" ] && CMD="ssh $i $CMD"
		echo "$CMD"
		[ _"$EXEC" != _ ] && $CMD
	fi
	rm $TMP.z
done

[ _"$ZONE_NAME" = _ ] && Exit 0
echo ""
STARTF=
X=`metaset -s $METASET 2> /dev/null | grep "$THIS_HOST"`
[ _"$X" = _ ] && err "can't see metaset $METASET on this host"	# no return
Y=`expr "$X" : "\(.*[ $TAB]Yes\)"`
if [ _"$Y" = _ ]
then
	CMD="metaset -s $METASET -t"
	echo "$CMD"
	if [ _"$EXEC" != _ ]
	then
		$CMD
		X=`metaset -s $METASET 2> /dev/null | grep "$THIS_HOST[ $TAB][ $TAB]*Yes"`
		[ _"$X" = _ ] && err "failed to take ownership of metaset $METASET"	# no return
	fi
fi
for i in `grep "^mount " $TMP.master | cut -d' ' -f2 | sed "s/\\$ZONE_NAME/$ZONE_NAME/"`
do
	if [ ! -d $i ]
	then
		CMD="mkdir -m 0755 -p $i"
		echo "$CMD"
		[ _"$EXEC" != _ ] && $CMD
	fi
	X=`mount | grep "^$i[ $TAB]"`
	if [ _"$X" = _ ]
	then
		CMD="mount $i"
		echo "$CMD"
		if [ _"$EXEC" != _ ]
		then
			$CMD
			X=`mount | grep "^$i[ $TAB]"`
			[ _"$X" = _ ] && err "failed to mount $i"	# no return
		fi
		STARTF=true
	fi
done
for i in `grep "^lofs " $TMP.master | cut -d' ' -f2 | sed "s/\\$ZONE_NAME/$ZONE_NAME/"`
do
	if [ ! -d $i ]
	then
		CMD="mkdir -m 0755 -p $i"
		echo "$CMD"
		[ _"$EXEC" != _ ] && $CMD
	fi
	X=`mount | grep "^$i[ $TAB]"`
	if [ _"$X" = _ ]
	then
		CMD="mount $i"
		echo "$CMD"
		if [ _"$EXEC" != _ ]
		then
			$CMD
			X=`mount | grep "^$i[ $TAB]"`
			[ _"$X" = _ ] && err "failed to mount $i"	# no return
		fi
		STARTF=true
	fi
done
ifconfig -a > $TMP.if
netfiddle $TMP.if
zlogin $ZONE_NAME "ifconfig -a" > $TMP.ifz
netfiddle $TMP.ifz
OUTF=
grep "^plumb " $TMP.master | cut -d' ' -f2- | while read LINE
do
	X_IF=`echo "$LINE" | cut -d' ' -f1`
	X_IP=`echo "$LINE" | cut -d' ' -f2`
	X_MASK=`echo "$LINE" | cut -d' ' -f3`
	X_ZN=`echo "$LINE" | cut -d' ' -f4`
	# cut returns last field if subsequent ones are missing (sigh)
	[ _"$X_IF $X_IP $X_MASK $X_ZN" != _"$LINE" ] && X_ZN=
	[ _"$X_ZN" != _ -a _"$X_ZN" != _"$ZONE_NAME" ] && continue
	X=`grep " $X_IP\$" $TMP.ifz`
	if [ _"$X" = _ ]
	then
		if [ _"$OUTF" = _ ]
		then
			if [ _"$EXCL" = _ ]
			then
				echo "$ZONE_NAME is shared-IP"
			else
				echo "$ZONE_NAME is exclusive-IP"
			fi
		fi
		OUTF=true
		if [ _"$EXCL" = _ ]
		then
			X=`grep "^$X_IF " $TMP.if`
			if [ _"$X" = _ ]
			then
				echo "$X_IF must be plumbed in the global first"
				CMD=
			else
				CMD="ifconfig $X_IF addif $X_IP netmask $X_MASK broadcast + zone $ZONE_NAME up"
			fi
		else
			X=`grep "^$X_IF " $TMP.ifz`
			if [ _"$X" = _ ]
			then
				X=`grep "^$X_IF " $TMP.if`
				if [ _"$X" != _ ]
				then
					echo "$X_IF must not be plumbed in teh global"
					CMD=
				else
					CMD="zlogin $ZONE_NAME ifconfig $X_IF plumb $X_IP netmask $X_MASK broadcast + up"
				fi
			else
				CMD="zlogin $ZONE_NAME ifconfig $X_IF addif $X_IP netmask $X_MASK broadcast + up"
			fi
		fi
		if [ _"$CMD" != _ ]
		then
			echo "$CMD"
			[ _"$EXEC" != _ ] && $CMD
		fi
		STARTF=true
	fi
done
rm $TMP.if $TMP.ifz
[ _"$STARTF" != _ ] && Start_App
Exit 0

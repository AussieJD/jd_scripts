#!/bin/sh

# migrate zone from another host in HLIST (below) to this host
#
# both remote and local host must have vfstab entries and access to /UVH
# local host must also have access to the relevant metaset
#
# will shut zone down if found running anywhere
#
# assumptions:
#	zonepath is a mounted filesystem from a dedicated metaset
#	any other zone filesystems are from the same metaset and are mounted
#	    under $ZONESFS/$ZONE_NAME
#	all such filesystems are mount-at-boot "no" in vfstab

TMP=/tmp/uvh.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

TAB='	'	# care - tab (don't cut and paste)

HLIST="auszvuvh001 auszvuvh002 auszvuvh004 auszvuvh005"

THIS_HOST=`hostname | cut -f1 -d.`
VFSTAB=/etc/vfstab
ZONESFS=/zones/fs	# zone loopback mounts are first mounted here
STATUS=0
UVH_Z_CONFCHK=/UVH/bin/uvh-zone-confchk.sh

umask 022

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

if [ $# != 1 ]
then
	echo "Usage: $0 <zone-name>"
	Exit 1
fi
ZONE_NAME=$1

err()
{
	echo "$1"
	echo ""
	echo "any actions that may have been listed above have been executed"
	echo "fix the problem indicated and run this script again to continue"
	Exit 1
}

Umount()
{
	H="$1"
	D="$2"

	CMD="ssh $H umount $D"
	echo "$CMD"
	$CMD
	X=`ssh $H "mount | grep \^$D"`
	[ _"$X" = _ ] && return
	# stupid HP monitoring tool likes to sit on mountpoints, preventing
	#   them unmounting - restarting it makes it go away
	echo "failed to unmount $D on $H - restarting system monitor"
	CMD="ssh $H sh /etc/init.d/lw_agt restart"
	echo "$CMD"
	$CMD
	CMD="ssh $H umount $D"
	echo "$CMD"
	$CMD
	X=`ssh $H "mount | grep \^$D"`
	[ _"$X" != _ ] && err "failed to unmount $D on $H"	# no return
}

ZCV=/UVH/etc/zone-create.$ZONE_NAME
[ ! -r "$ZCV" ] && err "$ZCV not found"	# no return
ZDIR=`grep zonepath= $ZCV | cut -f2 -d=`
[ _"$ZDIR" = _ ] && err "zonepath not found in $ZCV"	# no return
grep -v "^#" $VFSTAB | sed "s/[ $TAB][ $TAB]*/ /g" | grep " ufs " > $TMP.fs
METASET=`grep " $ZDIR .* no " $TMP.fs`
[ _"$METASET" = _ ] && err "can't find $ZDIR entry in $VFSTAB"	# no return
METASET=`expr "$METASET" : "/dev/md/\([^ $TAB]*\)/dsk/.*"`
[ _"$METASET" = _ ] && err "$ZDIR entry in $VFSTAB is not a metaset"	# no return
RUNLIST=
COUNT=0
for i in $HLIST
do
	X=`ssh $i "zoneadm -z $ZONE_NAME list -v 2> /dev/null | grep running"`
	if [ _"$X" != _ ]
	then
		COUNT=`expr $COUNT + 1`
		RUNLIST="$RUNLIST $i"
	fi
done
if [ $COUNT = 0 ]
then
	echo "$ZONE_NAME not running anywhere"
elif [ $COUNT = 1 ]
then
	echo "$ZONE_NAME running on$RUNLIST"
	if [ _"$RUNLIST" = _" $THIS_HOST" ]
	then
		echo "which is this host - nothing to do"
		Exit 0
	fi
else
	echo "$ZONE_NAME running on multiple hosts:$RUNLIST"
	X=`echo "$RUNLIST " | grep " $THIS_HOST "`
	if [ _"$X" != _ ]
	then
		echo "which includes this host - exiting"
		Exit 0
	fi
fi
echo "$ZONE_NAME will be moved to this host ($THIS_HOST) - confirm: (y|[n]) \c"
read ANS
ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
if [ _"$ANS" != _y ]
then
	echo "exiting"
	Exit 0
fi
for i in $RUNLIST
do
	if [ ! -x $UVH_Z_CONFCHK ]
	then
		echo "can't find $UVH_Z_CONFCHK to check configuration file"
	else
		ssh $i "zonecfg -z $ZONE_NAME info 2> /dev/null" > $TMP.z
		$UVH_Z_CONFCHK $ZONE_NAME $TMP.z
		if [ $? != 0 ]
		then
			echo ""
			echo "are you sure? (y|[n]) \c"
			read ANS
			ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
			if [ _"$ANS" != _y ]
			then
				echo exiting
				Exit 0
			fi
		fi
		rm $TMP.z
	fi
	ssh $i "zlogin $ZONE_NAME who" > $TMP.w
	X=`wc -l < $TMP.w`
	if [ $X -eq 0 ]
	then
		echo "no one logged in to zone $ZONE_NAME on host $i"
	else
		X=`echo $X`	# trim leading spaces
		echo ""
		echo "$X logins in zone $ZONE_NAME on host $i:"
		cat $TMP.w
	fi
	rm $TMP.w
	echo "shutdown immediate $ZONE_NAME on $i? (y|[n]) \c"
	read ANS
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	if [ _"$ANS" != _y ]
	then
		echo "nothing changed - exiting"
		Exit 0
	fi
	CMD="ssh $i zlogin $ZONE_NAME \"shutdown -i5 -g0 -y\""
	echo "$CMD"
	$CMD > /dev/null 2>&1
	FLAG=
	while true
	do
		if [ _"$FLAG" = _ ]
		then
			echo "waiting for zone to shutdown\c"
			FLAG=true
		else
			echo ".\c"
		fi
		X=`ssh $i "zoneadm -z $ZONE_NAME list -v | grep installed"`
		if [ _"$X" != _ ]
		then
			echo ""
			break
		fi
		sleep 5
	done
done
rm -f $TMP.i $TMP.o
for i in $HLIST
do
	[ _"$i" = _"$THIS_HOST" ] && continue
	X=`ssh $i "zoneadm -z $ZONE_NAME list -v 2> /dev/null | grep installed"`
	if [ _"$X" != _ ]
	then
		CMD="ssh $i zoneadm -z $ZONE_NAME detach"
		echo "$CMD"
		$CMD
	fi
	cp /dev/null $TMP.d
	ZDEL=
	X=`ssh $i "zoneadm -z $ZONE_NAME list -v 2> /dev/null"`
	if [ _"$X" != _ ]
	then
		ssh $i "zonecfg -z $ZONE_NAME info | grep special: | cut -f2 -d:" > $TMP.d
		ZDEL=true
	fi
	X=`ssh $i "mount | grep \^$ZDIR"`
	[ _"$X" != _ ] && Umount $i $ZDIR
	for j in `grep $ZONESFS/ $TMP.d`
	do
		X=`ssh $i "mount | grep \^$j\ "`
		[ _"$X" != _ ] && Umount $i $j
	done
	X=`ssh $i "ls -d $ZDIR 2> /dev/null"`
	if [ _"$X" != _ ]
	then
		CMD="ssh $i rmdir $ZDIR"
		echo "$CMD"
		$CMD
	fi
	for j in `grep $ZONESFS/ $TMP.d`
	do
		 X=`ssh $i "ls -d $j 2> /dev/null"`
		if [ _"$X" != _ ]
		then
			CMD="ssh $i rmdir $j"
			echo "$CMD"
			$CMD
		fi
	done
	rm $TMP.d
	for j in `ssh $i "ls $ZONESFS/$ZONE_NAME 2> /dev/null"`
	do
		j=$ZONESFS/$ZONE_NAME/$j
		CMD="ssh $i rmdir $j"
		echo "$CMD"
		$CMD
	done
	X=`ssh $i "ls -d $ZONESFS/$ZONE_NAME 2> /dev/null"`
	if [ _"$X" != _ ]
	then
		CMD="ssh $i rmdir $ZONESFS/$ZONE_NAME"
		echo "$CMD"
		$CMD
	fi
	X=`ssh $i "ls -d $ZONESFS 2> /dev/null"`
	if [ _"$X" != _ ]
	then
		X=`ssh $i "ls $ZONESFS"`
		if [ _"$X" = _ ]
		then
			CMD="ssh $i rmdir $ZONESFS"
			echo "$CMD"
			$CMD
		fi
	fi
	if [ _"$ZDEL" != _ ]
	then
		CMD="ssh $i zonecfg -z $ZONE_NAME delete -F"
		echo "$CMD"
		$CMD
	fi
	MSET=`ssh $i "grep -v '^#' $VFSTAB" | grep "[ $TAB]$ZDIR[ $TAB].*[ $TAB]no[ $TAB]"`
	[ _"$MSET" = _ ] && continue
	MSET=`expr "$MSET" : "/dev/md/\([^ $TAB]*\)/dsk/.*"`
	[ _"$MSET" = _ ] && continue
	X=`ssh $i metaset -s $MSET 2> /dev/null | grep "$i"`
	if [ _"$X" != _ ]
	then
		X=`expr "$X" : "\(.*[ $TAB]Yes\)"`
		if [ _"$X" != _ ]
		then
			CMD="ssh $i metaset -s $MSET -r"
			echo "$CMD"
			$CMD
		fi
	fi
done

echo ""
X=`metaset -s $METASET 2> /dev/null | grep "$THIS_HOST"`
[ _"$X" = _ ] && err "can't see metaset $METASET on this host"	# no return
Y=`expr "$X" : "\(.*[ $TAB]Yes\)"`
if [ _"$Y" = _ ]
then
	CMD="metaset -s $METASET -t"
	echo "$CMD"
	$CMD
	X=`metaset -s $METASET 2> /dev/null | grep "$THIS_HOST[ $TAB][ $TAB]*Yes"`
	[ _"$X" = _ ] && err "failed to take ownership of metaset $METASET"	# no return
fi
if [ ! -d "$ZDIR" ]
then
	CMD="mkdir -m 0700 $ZDIR"
	echo "$CMD"
	$CMD
fi
X=`mount | grep "^$ZDIR[ $TAB]"`
if [ _"$X" = _ ]
then
	CMD="mount $ZDIR"
	echo "$CMD"
	$CMD
	X=`mount | grep "^$ZDIR[ $TAB]"`
	[ _"$X" = _ ] && err "failed to mount $ZDIR"	# no return
fi
grep " $ZONESFS/$ZONE_NAME/.* no " $TMP.fs |
    sed "s/[^ ]* [^ ]* \([^ ]*\) .*/\1/" > $TMP.x
for i in `cat $TMP.x`
do
	if [ ! -d $i ]
	then
		CMD="mkdir -m 0700 -p $i"
		echo "$CMD"
		$CMD
	fi
	X=`mount | grep "^$i[ $TAB]"`
	if [ _"$X" = _ ]
	then
		CMD="mount $i"
		echo "$CMD"
		$CMD
		X=`mount | grep "^$i[ $TAB]"`
		[ _"$X" = _ ] && err "failed to mount $i"	# no return
	fi
done
rm $TMP.x
X=`zoneadm -z $ZONE_NAME list -v 2> /dev/null`
if [ _"$X" = _ ]
then
	CMD="zonecfg -z $ZONE_NAME -f $ZCV"
	echo "$CMD"
	$CMD
	X=`zoneadm -z $ZONE_NAME list -v 2> /dev/null`
	[ _"$X" = _ ] && err "failed to create zone $ZONE_NAME"	# no return
fi
X=`zoneadm -z $ZONE_NAME list -v 2> /dev/null | grep installed`
if [ _"$X" = _ ]
then
	CMD="zoneadm -z $ZONE_NAME attach -F"
	echo "$CMD"
	$CMD
	X=`zoneadm -z $ZONE_NAME list -v 2> /dev/null | grep installed`
	[ _"$X" = _ ] && err "failed to attach zone $ZONE_NAME"	# no return
fi
X=`grep "create -t SUNWsolaris" $ZCV | cut -f2 -dW`
CMD=
if [ _"$X" = _solaris8 ]
then
	CMD="/usr/lib/brand/solaris8/s8_p2v $ZONE_NAME"
elif [ _"$X" = _solaris9 ]
then
	CMD="/usr/lib/brand/solaris9/s9_p2v $ZONE_NAME"
elif [ _"$X" != _ ]
then
	err "don't recognise branded type $X"	# no return
fi
if [ _"$CMD" != _ ]
then
	# hostid a branded zone was last run on is stored in /.host.orig
	X=
	F=$ZDIR/root/.host.orig
	[ -s $F ] && X=`cat $F`
	Y=`hostid`
	if [ _"$X" != _"$Y" ]
	then
		echo "$CMD"
		$CMD > $TMP.x 2>&1
		grep . $TMP.x | sed "s/[ $TAB][ $TAB]*/ /g" |
		    grep -v " S20_apply_patches: Unpacking patch: [0-9][-0-9]*\$" |
		    grep -v " S20_apply_patches: Installing patch: [0-9][-0-9]*\$" |
		    grep -v "Checking installed patches...\$" |
		    grep -v "A later version of .* has already been installed" |
		    grep -v "Patch .* has already been applied" |
		    grep -v "This patch is obsoleted by patch " |
		    grep -v "^been applied to this system.\$" |
		    grep -v "See patchadd.* for instructions" |
		    grep -v "Patchadd is terminating" > $TMP.y
		[ -s $TMP.y ] && cat $TMP.x
		rm $TMP.x $TMP.y
	fi
fi
EX_IP=`grep "ip-type=exclusive" $ZCV`
cat <<!

to make this change permanent and avoid periodic warnings, update the master
file /UVH/etc/uvh-master (and any local copies using uvh-update.sh) with

!
if [ _"$EX_IP" = _ ]
then
	for i in `grep " physical=aggr" $ZCV | cut -f2 -d=`
	do
		echo "${TAB}$THIS_HOST plumb $i"
	done
fi
echo "${TAB}$THIS_HOST metaset $METASET"
echo "${TAB}$THIS_HOST mount $ZDIR"
for i in `grep " special=$ZONESFS/" $ZCV | cut -f2 -d=`
do
	echo "${TAB}$THIS_HOST mount $i"
done
echo "${TAB}$THIS_HOST zone $ZONE_NAME"
for i in `grep " special=" $ZCV | cut -f2 -d=`
do
	echo "${TAB}$THIS_HOST lofs $i"
done
echo ""
if [ _"$EX_IP" = _ ]
then
	Y=
	for i in `grep " physical=" $ZCV | cut -f2 -d=`
	do
		X=`ifconfig $i 2> /dev/null | grep UP`
		[ _"$X" = _ ] && Y="$Y $i"
	done
	if [ _"$Y" != _ ]
	then
		echo "can't boot $ZONE_NAME due to required NICs not up:$Y"
	fi
else
	dladm show-link | sed "s/[ $TAB].*//" > $TMP.dl
	Y=
	for i in `grep " physical=" $ZCV | cut -f2 -d=`
	do
		X=`grep "^$i\$" $TMP.dl`
		[ _"$X" != _ ] && Y="$Y $i"
	done
	rm $TMP.dl
	if [ _"$Y" != _ ]
	then
		echo "can't boot $ZONE_NAME due to required NICs already up:$Y"
	fi
fi
if [ _"$Y" = _ ]
then
	echo "boot $ZONE_NAME on $THIS_HOST? (y|[n]) \c"
	read ANS
	ANS=`echo "$ANS" | tr "[A-Z]" "[a-z]"`
	if [ _"$ANS" = _y ]
	then
		CMD="zoneadm -z $ZONE_NAME boot"
		echo "$CMD"
		$CMD
		[ $? != 0 ] && Exit 1
		cat <<!

connecting to zone to monitor boot messages
enter <CR>~. to disconnect

!
		CMD="zlogin -C $ZONE_NAME"
		echo "$CMD"
		$CMD
	fi
fi

Exit 0

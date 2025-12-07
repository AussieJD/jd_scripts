#!/bin/sh

# manage aggregates

# VLAN HOST IP
VHI_LIST="
   99  001 205.239.182.20
   99  004 205.239.182.21
  100  001 134.251.166.230
  100  004 134.251.166.231
  112  001 139.73.132.210
  112  004 139.73.132.211
 1303  001 205.239.124.70
 1303  004 205.239.124.71
 1306  001 139.73.190.120
 1306  004 139.73.190.121
 1307  001 134.251.189.200		# not allocated by Brian
 1307  004 134.251.189.201		# not allocated by Brian
#1504  001 15.147.124.5
#1504  004 15.147.124.8
 1904  001 205.239.143.25
 1904  004 205.239.143.26
 1906  001 139.73.184.130
 1906  004 139.73.184.131
 1944  001 134.251.163.147
 1944  004 134.251.163.148
"

# VLAN AGGR NETWORK       MASK
VANM_LIST="
    99   3 205.239.182.0   26		# brick2, lazarus{2} [0-63,64-127,128-191,192-255]
   100   2 134.251.166.128 25		# sir-d, sir-p2
   112   5 139.73.132.128  25		# apcap
  1303   5 205.239.124.0   24		# tarantella
  1306   4 139.73.190.0    24		# tarantella
  1307   6 134.251.189.192 26		# ausy19; not stretched yet
   xxx   6 134.251.163.0   24		# missing tarantella subnet
  1504   1 15.147.112.0    20		# DP
  1904   5 205.239.143.0   24		# aubwsgipw100,101
  1906   5 139.73.184.0    24		# aubwsgipw100,101
  1944   1 134.251.163.0   24		# aubwtsdnt001,2,3
"

# AGGR DEV0  DEV1
ADD_LIST="
    1  igb15 igb3
    2  igb12 igb2
    3  igb13 igb8
    4  igb14 igb9
    5  igb6  igb4
    6  igb7  igb5
"

# list of UVH servers of interest
SERVER_LIST="001 004"

# list of remote servers of interest
# VLAN HOST           IP
TARGETS="
    99 brick2         205.239.182.27
    99 lazarus2       205.239.182.5
   100 sir-d/syd0295  134.251.166.219
   100 sir-p2/syd0201 134.251.166.133
   112 apcap/syd0497  139.73.132.160
  1303 aubwtsdnt001   205.239.124.32
  1303 aubwtsdnt002   205.239.124.33
  1303 aubwtsdnt003   205.239.124.34
  1306 aubwtsdnt001   139.73.190.11
  1306 aubwtsdnt002   139.73.190.12
  1306 aubwtsdnt003   139.73.190.13
  1306 aubwsacc003    139.73.190.23
  1306 aubwsacc004    139.73.190.24
  1306 aubwsacc005    139.73.190.25
  1306 aubwsacc006    139.73.190.26
  1306 aubwsacc007    139.73.190.27
  1306 aubwsacc008    139.73.190.28
  1306 aubwsacc015    139.73.190.17
  1306 aubwsacc016    139.73.190.18
  1306 aubwsacc017    139.73.190.19
  1306 aubwsacc018    139.73.190.20
  1306 aubwsvugl023   139.73.190.90
  1307 ausy19         134.251.189.194
  1504 auszsbudp001   15.147.112.12
  1904 aubwsgipw100   205.239.143.46
  1904 aubwsgipw100   205.239.143.52
  1904 aubwsgipw100   205.239.143.53		# 2x interfaces up ??? check me
  1904 aubwsgipw101   205.239.143.49
  1906 aubwsgipw100   139.73.184.48
  1906 aubwsgipw101   139.73.184.49
  1906 aubwsgipw101   139.73.184.50		# 2x interfaces up ??? check me
  1944 aubwtsdnt001   134.251.163.142
  1944 aubwtsdnt002   134.251.163.143
  1944 aubwtsdnt003   134.251.163.144
"

# no config data should be below here
######################################################################

TMP=/tmp/vlans.$$
trap "rm -f $TMP $TMP.* ; Exit" 0 2 3

TAB='	'	# care - tab!
STATUS=0
HOST_NUM=`hostname| cut -f1 -d.`
HOST_NUM=`expr "$HOST_NUM" : ".*\(...\)"`

# pre-digest lists to simplify subsequent testing
VHI_LIST=`echo "$VHI_LIST" | sed -e "s/[ $TAB][ $TAB]*/ /g"`
VHI_LIST=`echo "$VHI_LIST" | sed "s/^ //"`
VHI_LIST=`echo "$VHI_LIST" | sed -e "s/#.*//" -e "s/ \$//" -e "/^\$/d"`
VANM_LIST=`echo "$VANM_LIST" | sed -e "s/[ $TAB][ $TAB]*/ /g"`
VANM_LIST=`echo "$VANM_LIST" | sed "s/^ //"`
VANM_LIST=`echo "$VANM_LIST" | sed -e "s/#.*//" -e "s/ \$//" -e "/^\$/d"`
ADD_LIST=`echo "$ADD_LIST" | sed -e "s/[ $TAB][ $TAB]*/ /g"`
ADD_LIST=`echo "$ADD_LIST" | sed "s/^ //"`
ADD_LIST=`echo "$ADD_LIST" | sed -e "s/#.*//" -e "s/ \$//" -e "/^\$/d"`
TARGETS=`echo "$TARGETS" | sed -e "s/[ $TAB][ $TAB]*/ /g"`
TARGETS=`echo "$TARGETS" | sed "s/^ //"`
TARGETS=`echo "$TARGETS" | sed -e "s/#.*//" -e "s/ \$//" -e "/^\$/d"`


# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

usage()
{
	echo "Usage: $0 up|down|status|list [vlan#]"
	Exit 1
}

list()
{
	V="$1"

	vanm2x $V
	echo "$V   aggr$AGGR $NETW/$MASK"
	echo "$TARGETS" | grep "^$V " | while read LINE
	do
		X=`echo "$LINE" | cut -f2 -d' '`
		Y=`expr "$X" : ".*"`
		[ $Y -lt 8 ] && X="$X$TAB"
		Y=`echo "$LINE" | cut -f3 -d' '`
		echo "${TAB}$X${TAB}$Y"
	done
	for i in $SERVER_LIST
	do
		vh2ip $V $i
		echo "$TAB$i$TAB$TAB$IP"
	done
}

vh2ip()
{
	V="$1"
	H="$2"

	IP=`echo "$VHI_LIST" | grep "^$V $H " | tail -1 | cut -f3 -d' '`
	if [ _"$IP" = _ ]
	then
		echo "vlan $V host $H no IP"
		Exit 1
	fi
}

vanm2x()
{
	V="$1"

	LINE=`echo "$VANM_LIST" | grep "^$V " | tail -1`
	AGGR=`echo "$LINE" | cut -f2 -d' '`
	NETW=`echo "$LINE" | cut -f3 -d' '`
	MASK=`echo "$LINE" | cut -f4 -d' '`
	if [ _"$AGGR" = _ -o _"$NETW" = _ -o _"$MASK" = _ ]
	then
		echo "vlan $V bad"
		Exit 1
	fi
}

add2x()
{
	A="$1"

	LINE=`echo "$ADD_LIST" | grep "^$A " | tail -1`
	DEV0=`echo "$LINE" | cut -f2 -d' '`
	DEV1=`echo "$LINE" | cut -f3 -d' '`
	if [ _"$DEV0" = _ -o _"$DEV1" = _ ]
	then
		echo "aggr $A bad"
		Exit 1
	fi
}

va2s()
{
	V="$1"
	A="$2"

	X=`expr "$A" : "\([0-9][0-9]*\)\$"`
	if [ _"$X" = _ -o _"$X" != _"$A" ]
	then
		echo "non-digits in aggr for vlan $V"
		return 1
	fi
	if [ $A -lt 9 ]
	then
		X=00$A
	elif [ $A -lt 99 ]
	then
		X=0$A
	else
		X=$A
	fi
	SUFFIX=$V$X
	return 0
}

cr_aggr()
{
	A="$1"

	add2x $A
	for i in $DEV0 $DEV1
	do
		if [ _"`grep \"^$i: \" $TMP.i`" != _ ]
		then
			echo "$i must be unplumbed first"
			return 1
		fi
	done
	CMD="dladm create-aggr -l active -d $DEV0 -d $DEV1 $A"
	echo "$CMD"
	$CMD
	return $?
}

up()
{
	V="$1"

	vh2ip $V $HOST_NUM
	vanm2x $V
	if [ _"`grep \" $AGGR \" $TMP.a`" = _ ]
	then
		cr_aggr $AGGR
		[ $? != 0 ] && return
	fi
	va2s $V $AGGR
	[ $? != 0 ] && return
	[ _"`grep \"aggr$SUFFIX: .*UP,\" $TMP.i`" != _ ] && return
	X=
	[ _`grep "aggr$SUFFIX: " $TMP.i` = _ ] && X="plumb "
	case "$MASK"
	in
	20)	NETMASK=255.255.240.0 ;;
	24)	NETMASK=255.255.255.0 ;;
	25)	NETMASK=255.255.255.128 ;;
	26)	NETMASK=255.255.255.192 ;;
	*)	echo "need more netmasks!" ; Exit 1 ;;
	esac
	CMD="ifconfig aggr$SUFFIX $X$IP netmask $NETMASK broadcast + up"
	echo "$CMD"
	$CMD
}

down()
{
	V="$1"

	vanm2x $V
	va2s $V $AGGR
	[ $? != 0 ] && return
	if [ _"`grep \"^aggr$SUFFIX\$\" $TMP.d`" = _ ]
	then
		echo "aggr$SUFFIX not plumbed"
		return
	fi
	CMD="ifconfig aggr$SUFFIX unplumb"
	echo "$CMD"
	$CMD 2> /dev/null
}

status()
{
	V="$1"

	vanm2x $V
	va2s $V $AGGR
	[ $? != 0 ] && return
	CMD="ifconfig aggr$SUFFIX"
	printf "$CMD: "
	X=`$CMD 2> /dev/null`
	Y=`echo "$X" | grep UP`
	if [ _"$Y" != _ ]
	then
		echo "up"
	elif [ _"$X" != _ ]
	then
		echo "plumbed"
	else
		echo "not plumbed"
	fi
}

[ $# != 1 -a $# != 2 ] && usage
ACTION="$1"
VLAN="$2"

case "$ACTION"
in
up)
	dladm show-aggr | grep "^key:" | cut -f1 -d'(' | cut -f2 -d: > $TMP.a
	ifconfig -a | grep -v "^[ $TAB]" > $TMP.i
	for i in `echo "$VANM_LIST" | cut -f1 -d' '`
	do
		[ _"$VLAN" = _ -o _"$VLAN" = _"$i" ] && up "$i"
	done
	rm $TMP.a $TMP.i
	;;
down)
	ifconfig -a | grep "^aggr" | cut -f1 -d: > $TMP.d
	for i in `echo "$VANM_LIST" | cut -f1 -d' '`
	do
		[ _"$VLAN" = _ -o _"$VLAN" = _"$i" ] && down "$i"
	done
	rm $TMP.d
	;;
status)
	for i in `echo "$VANM_LIST" | cut -f1 -d' '`
	do
		[ _"$VLAN" = _ -o _"$VLAN" = _"$i" ] && status "$i"
	done
	;;
list|info)
	for i in `echo "$VANM_LIST" | cut -f1 -d' '`
	do
		[ _"$VLAN" = _ -o _"$VLAN" = _"$i" ] && list "$i"
	done
	;;
*)
	usage
	;;
esac

Exit 0

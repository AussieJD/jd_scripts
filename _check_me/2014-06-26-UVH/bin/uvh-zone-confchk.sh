#!/bin/sh

# check zonecfg output against configuration script $ZCV

TMP=/tmp/uvh.$$
trap "rm -f $TMP.? ; Exit" 0 2 3

TAB='	'	# care - tab (don't cut and paste)
STATUS=0

# needed to control trap-exit above
Exit()
{
	[ _"$1" != _ ] && STATUS=$1
	exit $STATUS
}

if [ $# != 1 -a $# != 2 ]
then
	echo "Usage: $0 <zone-name> [zonecfg-output]"
	Exit 1
fi
ZONE_NAME=$1
ZCFG_OUT=$2

ZCV=/UVH/etc/zone-create.$ZONE_NAME
if [ ! -r "$ZCV" ]
then
	echo "$ZCV not found"
	Exit 1
fi

# try to recreate the zone configuration script to compare
#
# assumes a fairly simple style of configuration - if this becomes
# unusual, the below will have to be expanded
if [ _"$ZCFG_OUT" = _ ]
then
	ZCFG_OUT=$TMP.z
	zonecfg -z $ZONE_NAME info > $ZCFG_OUT
elif [ ! -s "$ZCFG_OUT" ]
then
	echo "can't find $ZCFG_OUT"
	Exit 1
fi
grep . $ZCFG_OUT |
    sed -e "s/[ $TAB][ $TAB]*/ /g" > $TMP.o
if [ ! -s $TMP.o ]
then
	echo "no running configuration"
	Exit 1
fi
rm -f $TMP.z
ed - $TMP.o <<!
g/defrouter not specified/d
g/physical:/?^net?,.j
g/defrouter: /-,.j
g/raw not specified/d
g/options: /?^fs?,.j
w
!
X=`grep "^brand: " $TMP.o | cut -f2 -d' '`
if [ _"$X" = _solaris9 ]
then
	X="-t SUNWsolaris9"
elif [ _"$X" = _solaris8 ]
then
	X="-t SUNWsolaris8"
elif [ _"$X" = _native ]
then
	X=`grep "^inherit-pkg-dir:" $TMP.o`
	[ _"$X" = _ ] && X="-b" || X=
else
	echo "zone $ZONE_NAME on host $i unknown brand <$X>"
	Exit 1
fi
[ _"$X" != _ ] && X=" $X"
echo "create$X" > $TMP.i
X=`grep "^zonepath: " $TMP.o | cut -f2 -d' '`
[ _"$X" != _ ] && echo "set zonepath=$X" >> $TMP.i
X=`grep "autoboot:" $TMP.o | cut -f2 -d' '`
echo "set autoboot=$X" >> $TMP.i
X=`grep "bootargs:" $TMP.o | sed "s/[^ ]* \(.*\)/\1/"`
echo "set bootargs=\"$X\"" >> $TMP.i
X=`grep "ip-type:" $TMP.o | sed "s/[^ ]* \(.*\)/\1/"`
[ _"$X" = _exclusive ] && echo "set ip-type=$X" >> $TMP.i
X=`grep "^hostid: " $TMP.o | cut -f2 -d' '`
[ _"$X" != _ ] && echo "set hostid=$X" >> $TMP.i
grep "^fs: " $TMP.o | while read LINE
do
	echo "add fs"
	X=`expr "$LINE" : ".* dir: \([^ ]*\)"`
	echo "set dir=$X"
	X=`expr "$LINE" : ".* special: \([^ ]*\)"`
	echo "set special=$X"
	X=`expr "$LINE" : ".* type: \([^ ]*\)"`
	echo "set type=$X"
	X=`expr "$LINE" : ".* options: \(\[[^ ]*]\)"`
	[ _"$X" != _ -a _"$X" != _"[]" ] && echo "set options=$X"
	echo "end"
done >> $TMP.i
grep "^net: " $TMP.o | while read LINE
do
	echo "add net"
	X=`expr "$LINE" : ".* address: \([^ ]*\)"`
	[ _"$X" != _ ] && echo "set address=$X"
	X=`expr "$LINE" : ".* physical: \([^ ]*\)"`
	echo "set physical=$X"
	X=`expr "$LINE" : ".* defrouter: \([^ ]*\)"`
	[ _"$X" != _ ] && echo "set defrouter=$X"
	echo "end"
done >> $TMP.i
X=`grep " \[ncpus: " $TMP.o | sed "s/ [^ ]* \(.*\)]/\1/"`
if [ _"$X" != _ ]
then
	cat >> $TMP.i <<!
add capped-cpu
set ncpus=$X
end
!
fi
cat >> $TMP.i <<!
verify
commit
!
cmp -s $TMP.i $ZCV
if [ $? != 0 ]
then
	echo "warning: running zone configuration differs from"
	echo "   $ZCV:"
	echo ""
	echo "diff [running] [script]"
	diff $TMP.i $ZCV
	Exit 1
fi
Exit 0

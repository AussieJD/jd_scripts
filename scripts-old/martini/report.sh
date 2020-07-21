#!/bin/bash
SNAPMIRRORS=$1.snapmirrors
echo dos2unix first
dos2unix < $1 > ${1}.unix
echo extract snapmirrors
./martini_snapmirrors.sh ${1}.unix > ${SNAPMIRRORS}
#
echo volume report
./martini_vol.sh ${1}.unix $SNAPMIRRORS > $1.volumes.csv

unix2dos $SNAPMIRRORS > $SNAPMIRRORS.txt
rm -f $SNAPMIRRORS
rm -f $1.unix
#
#

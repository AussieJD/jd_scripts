#!/bin/bash
CONTROLLER=undefined

#echo VolName VolName-All Contains_replicas SnapRes Size Used
echo VolName,VolName-All,Contains_replicas,SnapRes,SnapUsed,Size,Used
cat -n $1 | while read A B C D E F G H I J K L M N O P; do
  TYPE=no
  if [ "$B $C" = "Controller Name:" ]; then
    CONTROLLER=$D
  fi
  if [ "$G $H $I" = "in Volume Used" ]; then
    export LVOL=$[ $A - 2 ]
    VOLUME=$(head -n $LVOL $1 | tail -n 1)
    awk '{print $1 " " $3}' < $2 | grep $VOLUME > /dev/null
    if [ $? -eq 0 ]; then
      TYPE="Contains"
    fi
#
    export LSNAP=$[ $A - 1 ]
    SnapRes=$(head -n $LSNAP $1 | tail -n 1 | awk '{print $1}' )
 #   echo $SnapRes
#
#    echo $VOLUME ${CONTROLLER}-${VOLUME} $TYPE $SnapRes $E $B 
    echo $VOLUME,${CONTROLLER}-${VOLUME},$TYPE,$SnapRes,$J,$E,$B 
#    echo $CONTROLLER $TYPE $VOLUME used $B total $E snapused $J of $M
#    SnapRes=$(echo "scale=2; 100 / $B * $M" | bc -l)
#    awk '{print $1 " " $3}' < $2 | grep $VOLUME | [ ! $? -eq 0 ]; echo snap
  fi

#    export FILE=$1
#    export SRCL=$[ $A + 5 ]
#    export DSTL=$[ $A + 6 ]
#    #DST=$(head -n ${DSTL} $FILE | tail -n 1 )
#    #SRC=$(head -n ${SRCL} $FILE | tail -n 1 )
#    #
#    export ALTL=$[ $A + 8 ]
#    SRC=$(head -n ${ALTL} $FILE | tail -n 8 |egrep 'nas|vol|10.149' |head -n 1)
#    DST=$(head -n ${ALTL} $FILE | tail -n 8 |egrep 'nas|vol|10.149' |tail -n 1)
#    #echo $ALT
#    echo "$B $SRC $DST"
#  fi
done

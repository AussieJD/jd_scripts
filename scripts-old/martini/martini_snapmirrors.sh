#!/bin/bash

cat -n $1 | while read A B C D E F; do
  if [ $B = "Snapmirrored" ]; then
    export FILE=$1
    export SRCL=$[ $A + 5 ]
    export DSTL=$[ $A + 6 ]
    #DST=$(head -n ${DSTL} $FILE | tail -n 1 )
    #SRC=$(head -n ${SRCL} $FILE | tail -n 1 )
    #
    export ALTL=$[ $A + 8 ]
    SRC=$(head -n ${ALTL} $FILE | tail -n 8 |egrep 'nas|vol|10.149' |head -n 1)
    DST=$(head -n ${ALTL} $FILE | tail -n 8 |egrep 'nas|vol|10.149' |tail -n 1)
    #echo $ALT
    echo "$B $SRC $DST"
  fi
done

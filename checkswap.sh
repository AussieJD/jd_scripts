#!/usr/bin/ksh

###
### Checks swap space and reports on it with a 90% threshold.
###
### Demonstrates how to utilize substr and nawk to determine
### values.
###

### Threshold size swap should be before reporting it.
THRESHOLD=90

SWAP_SIZE_USED=`swap -s|nawk '{print substr($9,1,length($9)-1)}'`
SWAP_FREE=`swap -s|nawk '{print substr($11,1,length($11)-1)}'`
(( SWAP_PER_USE = SWAP_SIZE_USED * 100 / (SWAP_FREE + SWAP_SIZE_USED) ))
(( GB = SWAP_SIZE_USED / 1024 ))

if [ ${SWAP_PER_USE} -gt ${THRESHOLD} ]; then
	echo "`hostname`'s Memory is above the threshold of ${THRESHOLD}%"
else
	echo "`hostname`'s Memory  ${SWAP_PER_USE}% USED ($GB MB)"
fi

exit 0






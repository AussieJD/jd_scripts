#!/bin/ksh
#
# Usage: demonstrate keeping a counter at specified no of significant figures
#
count=1
while [ $count -le 105 ]
 do if [ $count -lt 10 ]; then prefix=000; elif [ $count -lt 100 ]; then prefix=00; else prefix=0;fi
echo $prefix$count
count=`expr $count + 1`
done

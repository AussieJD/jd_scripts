#!/bin/ksh
#
count=0
current=0
last=0
time=10
totaltime=0
totaldiff=0
diff=0
clear
ls -c | more
echo " ..above is the current directory."
echo " what string do you want to search for ... \c>"
read ans
echo "checking size every $time seconds....."
while true
do
current=`du -ks $ans | awk '{ print $1 }'`
if [ $count = "0" ];then diff=0 ;else diff=$(($current-$last))
if [ $diff = "0" ];then count2=$(($count2+1)); else count2=0;fi
fi
echo "pass $count"
echo " old = $last kb"
echo " new = $current kb"
echo " difference = $diff kb "
echo " rate = $(($diff/$time)) kb/s"
echo " total change = $totaldiff kb "
if [ $count = "0" ];then echo " average change = 0";else echo " average change = $(($totaldiff/$count)) kb";fi
if [ $count = "0" ];then echo " average rate = 0";else echo " average rate = $(($totaldiff/$totaltime)) kb/s ";fi
if [ $totaltime -le "60" ]; then echo " ...time testing = $totaltime secs. "
else echo " ...time testing = $((totaltime/60)) mins. "; fi
echo "zero change count = $count2 "
last=$current
sleep $time
totaltime=$(($totaltime+$time))
totaldiff=$(($totaldiff+$diff))
count=$(($count+1))
if [ $count2 = "5" ];then exit 1;fi
#clear
done

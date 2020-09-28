#!/bin/ksh
#
#	Usage		Look for all birthdays is a year/month/week
#	
#	Enhancement	make cron send a reminder at the start of the week of all b/days that week
#
# VARIABLES
command=$1
dateday=`date +%d`
datemonth=`date +%m`
dateyear=`date +%y`
reach=7			# days to scan from today
#
count1=1
count2=1
limit=31
while true
 do
	[ $count2 = 1 ] && month=Jan
	[ $count2 = 2 ] && month=Feb
	[ $count2 = 3 ] && month=Mar
	[ $count2 = 4 ] && month=Apr
	[ $count2 = 5 ] && month=May
	[ $count2 = 6 ] && month=Jun
	[ $count2 = 7 ] && month=Jul
	[ $count2 = 8 ] && month=Aug
	[ $count2 = 9 ] && month=Sep
	[ $count2 = 10 ] && month=Oct
	[ $count2 = 11 ] && month=Nov
	[ $count2 = 12 ] && month=Dec
	echo "--$count1/$month/$dateyear-- "
	dtcm_lookup -d $count1/$count2/$dateyear -v day | grep "(19"
	count1=$(($count1+1))
	[ $count1 -gt 31 ] && count2=$(($count2+1))
	[ $count1 -gt 31 ] && count1=1
	[ $count2 -gt 12 ] && exit 0
	content=0
done

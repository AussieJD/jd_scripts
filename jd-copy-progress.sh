#!/bin/bash
#
# Summary:	monitor the copy of a large amount of files / or a folder , giving stats on transfer rate, time remaining etc...
#
# Usage:	jd-copy-progress.sh original-file destination-file
#
# read in from command line
source=$1
dest=$2

time_to_sleep=10
change_mbytes_sec="wait"

#echo "Original:		$orig"
#echo "Destination:		$dest"
dest_size_kbytes=0

# temproarily removed the ability to get size of "source".... and setting a manual "source size"...
### origsize=`du -ks $orig |awk '{print $1}'`

# now set source size manually ....
source_size_kbytes=625000000 			# in kilobytes ... need to determine how to best set "orig" source size
source_size_mbytes=`echo $source_size_kbytes / 1024 | bc `
source_size_gbytes=`echo $source_size_mbytes / 1024 | bc `

while true
 do

# determine how much has been copied since last loop (kilobytes)

	dest_size_old_kbytes=$dest_size_kbytes						# store history of the last size of the destination in kilobytes
	dest_size_kbytes=`du -ks $dest | awk '{print $1}'`				# calculate the NEW size of the destination in kilobytes
	dest_size_mbytes=`echo $dest_size_kbytes / 1024 | bc`				# calculate the NEW size of the destination in megabytes
	dest_size_gbytes=`echo $dest_size_mbytes / 1024 | bc`				# calculate the NEW size of the destination in gigabytes
	percentage_done=`echo "scale=1; ($dest_size_kbytes / $source_size_kbytes) * 100" | bc`
	remaining_percentage=`echo 100 - $percentage_done | bc`

# determine how much to go  / remaining (total) 

	remaining_kbytes=`echo $source_size_kbytes - $dest_size_kbytes | bc`		# remaining data to copy in kilobytes
	remaining_mbytes=`echo $remaining_kbytes / 1024 | bc`				# remaining data to copy in megabytes
	remaining_gbytes=`echo $remaining_mbytes / 1024 | bc`				# remaining data to copy in gigabytes

# determine data rates etc 

	change_kbytes_time=`echo $dest_size_kbytes - $dest_size_old_kbytes |bc`		# change in last loop in kilobytes (elapsed = "$time_to_sleep" seconds)
	change_kbytes_sec=`echo ${change_kbytes_time} / $time_to_sleep | bc`		# change in last loop in kilobytes per second
	change_mbytes_sec=`echo ${change_kbytes_sec} / 1024 | bc`			# change in last loop in megabytes per second 

# determine how long to go ....

	to_go_seconds=`echo $remaining_kbytes / $change_kbytes_sec | bc`			# seconds remaining
	to_go_mins=`echo $to_go_seconds / 60 | bc`					# minutes remaining
	to_go_hours=`echo $to_go_mins / 60 | bc`					# hours remaining

# start output ... clean up screen  ...

clear
#
#	echo $origsize, $destsize 
# check
## ( echo " ...testing ... 
## x source_size_kbytes = $source_size_kbytes
## x dest_size_old_kbyte = $dest_size_old_kbytes
## x dest_size_kbytes = $dest_size_kbytes
## x dest_size_mbytes = $dest_size_mbytes
## x dest_size_gbytes = $dest_size_gbytes
## x percentage_done = $percentage_done
## x remaining_percentage = $remaining_percentage
## x remaining_kbytes = $remaining_kbytes
## x remaining_mbytes = $remaining_mbytes
## x change_kbytes_time = $change_kbytes_time
## x change_mbytes_sec = $change_mbytes_sec
## x to_go_seconds = $to_go_seconds
## x to_go_mins = $to_go_mins
## x to_go_hours = $to_go_hours
## ")

( echo "
-----------------------------------------------------

Transferring From: 		$source
To:   				$dest
---
Transferring:			$source_size_gbytes GB [ $source_size_mbytes MB ][ $source_size_kbytes kilobytes ] 
Transferred:			$dest_size_gbytes GB [ $dest_size_mbytes MB ][ $dest_size_kbytes kilobytes ]
---
Current Rate: 			$change_mbytes_sec MB/s [ $change_kbytes_sec kilobytes/sec ]
---
Percentage:			Done: 			$percentage_done %
				Remaining: 		$remaining_percentage %
---
Remaining: 			$remaining_gbytes GB [ $remaining_mbytes MB ] [ $to_go_mins minutes ][ $to_go_hours hours ]
---
To-Go:				$to_go_hours hours [ $to_go_mins minutes ] 

-----------------------------------------------------
")

#
	sleep $time_to_sleep
done
#
# The End!

#!/bin/bash
#
# Script:	reset-hp-printers.sh
#
# Function:	Reset HP print Services on OS X 
#
# Usage:	run using sudo 
#		(preferably put script in sudo allow list)
#
# Synopsis:	OS X fast user switching confuses printer operation
#		when relying on HP print services
#		This script can be run by any user to kill (and restart) 
#		HP printer services
#
# Start Script

# find and kill processes
PROCS=`ps -aux | egrep -i hp | egrep -v grep | egrep -v reset | awk '{print $2}'`
for i in $PROCS
 do
	echo $i
done

# The End!

#!/bin/bash
#
#
#
# Find and kill vncserver sessions for current user
#
PATH=$PATH:/usr/openwin/bin:/usr/X11/bin;export PATH
cd ~/.vnc
#
for i in `more *pid`
 do 	
	ID=`ps -ef | grep $i | grep Xvnc| awk '{print $9}'`
	echo "killing display $ID"
	vncserver -kill $ID
 done

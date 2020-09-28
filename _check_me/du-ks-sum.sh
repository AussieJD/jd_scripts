#!/bin/ksh
#
# Usage: sum file sizes for files matching requested string
#	
clear
echo "
--------------------------------------------------------------
This script will do a du -ks on all files (ls -l) that match 
the search strings
It will ask for what to match, and/or what to exclude.

	(Just hit <enter> for none.)
Have fun.
--------------------------------------------------------------
"
echo "\n Enter string(s) to match \t..>\c"
read stringin
echo "\n Enter string(s) to exclude \t..>\c"
read stringout
if [ "$stringin" = "" ]
then
	if [ "$stringout" = "" ]
	then
		echo " ... finding size for entire directory (and subfolders)"
		du -ks		
	else
		echo " ... finding size of all files except those with names matching \"$stringout\" "
		du -ks `ls -l | grep -v $stringout |awk '{ print $9 }'`| awk '{ sum = sum + $1 }{ print sum }'|tail -1
	fi
else	
	if [ "$stringout" = "" ]
        then
		echo " ... finding size of all files with names containing \"$stringin\" "
		du -ks `ls -l | grep $stringin |awk '{ print $9 }'`| awk '{ sum = sum + $1 }{ print sum }'|tail -1
	else
		echo " ... finding size of all files with names containing \"$stringin\", but not \"$stringout\" "
		du -ks `ls -l|grep $stringin|grep -v $stringout|awk '{ print $9 }'`| awk '{ sum = sum + $1 }{ print sum }'|tail -1
	fi
fi
echo " (kbytes) "
echo "\n---------------------------------------------------------------"

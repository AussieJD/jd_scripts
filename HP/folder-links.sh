#!/bin/bash
#
# create a list of http: links for sharepoint folder
#
## VAR
PWD1=`printf '%s\n' "${PWD##*/}"`		# get name of current folder
PWD2=`pwd | cut -d "/" -f7-`
FILE1="/tmp/$PWD1.folder.list"
FILE2="$PWD1.folder.links.html"
VAR1="http://ent212.sharepoint.hp.com/teams/apj_ito_transformation_dct/sp_dcc/Burwood%20%20Sysmc/EDS%20Leveraged%20-%20Leveraged%20Services%20and%20Tools"
DATE1=`date +%Y%m%d-%H:%M`

# SCRIPT

[ -f $FILE1 ] && rm $FILE1
[ -f $FILE2 ] && rm $FILE2
#[ -f $FILE2 ] && mv $FILE2 $FILE2.$DATE1

find . -type d >> $FILE1
cat $FILE1 | while read line 

 do
	echo "<a href=\"$VAR1/$PWD2/$line\">$line</a><br>" $'\r' >> $FILE2
#	echo $'\r' >> $FILE2
done

#cat $FILE2

# The End !

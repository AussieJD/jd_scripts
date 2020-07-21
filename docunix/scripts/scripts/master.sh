#!/usr/local/bin/bash

. /var/www/docunix/bin/scripts/variables

for i in `ls ${SCRIPTBASE} | grep \.sh | grep -v master`
 do
#	MYTITLE=`cat $i | grep MYTITLE | awk -F"=" '{print $2}'`
	echo "<tr><td colspan=${COLSPAN1}  bgcolor=${BGCOLOR2}><font color=${TEXTCOLOR1}> File = $i </font></td></tr>"
	$SCRIPTBASE/$i
done
		

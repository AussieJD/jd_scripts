#!/usr/local/bin/bash
#
. variables
#

HOSTS=0
MYTITLE=Some_Stats

echo "<tr><td>Number of Hosts (with explorers) in Docunix</td>"
echo "<td>"
for i in `ls -fd $BASE`
 do
	if [ -d $i ]
	 then	cd $BASE/$i
		COUNT=`ls | grep ^explorer | wc -l`
		HOSTS=$(( $HOSTS + $COUNT ))	
		cd $BASE
	fi
done
echo "$HOSTS</td>"
echo "</tr>"

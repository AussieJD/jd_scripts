#!/usr/local/bin/bash
# get today's date

. variables

MYTITLE=Explorers

FILE_COUNT=0

echo "<tr><td>Explorer List</td>"
echo "<td>"
echo "<pre>"
for i in `cat /var/docunix/etc/config | grep collection_dir | awk -F= '{print $2}'`
 do	
	echo "<br>Folder: $i<br>"
	for j in `ls $i | grep ^explorer | grep -v ".tar"`
	do
		echo " - Explorer: <a href=\"$i/$j\">$j</a>"
		FILE_COUNT=$(( $FILE_COUNT + 1 ))
	done
	echo ""
done
echo "</pre>"
echo "... done ($FILE_COUNT files)"
echo "</td></tr>"

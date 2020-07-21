#!/usr/local/bin/bash
# get today's date

. variables

MYTITLE=Solaris_Versions

# You must add following two lines before
# outputting data to the web browser from shell
# script

echo "<tr><td>"
echo "Solaris Versions"
echo "</td><td colspan=${COLSPAN1} >"
for i in `find -L $BASE | grep release`
 do	
	VAR2=`cat $i | grep Solaris`
	VAR3=`echo $VAR2 | awk '{print $2}'`
	if [ $VAR3 -eq 10 ]
	 then
		COUNT_10=$(( $COUNT_10 + 1 ))
	elif [ $VAR3 -eq 9 ]
	 then
		COUNT_9=$(( $COUNT_9 + 1 ))
	 else
		COUNT_OTHER=$(( $COUNT_OTHER + 1 ))
	fi
	HOSTID=`echo $i | sed -n 's/^.*explorer.\([^.]*\).*$/\1/p'`
        NAME=`echo $i | awk -F. '{print $3}' | awk -F"-" '{print $1}'`
        FILENAME=`echo $i |  awk -F/ '{print substr($0, index($0,$6)) }'`
        NAME2=`echo $i |  awk -F/ '{print $4}'`
        COLLECTION=`echo $i |  awk -F/ '{print $5}'`
        PATH2=`echo $i | awk -F/ '{print substr($0, index($0,$6)) }' | sed -e 's/\//%2F/'`
cat << EOF2
  	$NAME, $HOSTID, $VAR2,  
        File = <a href="http://16.176.23.32/bin/fileview?name=${NAME2}&collection=${COLLECTION}&path=${PATH2}" target=_blank>
         $FILENAME</a><br>
EOF2
done
cat << EOF3
</td></tr>
<tr><td colspan=${COLSPAN1} bgcolor=$BGCOLOR1 >Totals:<br><b>Solaris 9:     $COUNT_9<br>
Solaris 10:     $COUNT_10<br>
Solaris Other:     $COUNT_OTHER<br>
</td>
</tr>
EOF3

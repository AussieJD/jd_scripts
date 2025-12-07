#!/bin/bash
#
BASE1=/UVH/etc


echo "p
p
q
q" > /tmp/jdfmt

echo | format > /tmp/jdfmt2

printf "%-6s %-10s %-10s %-10s \n" LUN "Actual Size" "Label" "Planned Data"
for i in `cat /UVH/etc/uvh-disks | grep ^LUN | awk '{print $2}'`
 do 	
	z=`cat $BASE1/uvh-disks | grep $i|awk '{print $3" "$4}'`
	if [ `cat /tmp/jdfmt2|grep $i|awk '{print $6}'|sed 's/>//'` = "reserved" ] 
	 then
		y="" 
		x="not on this host"
	else
		cat /tmp/jdfmt | format c0t60060E8016025C000001025C00000${i} 2> /dev/null > /tmp/jdfmt3
		x=`cat /tmp/jdfmt3 | grep backup | grep GB|awk '{print $7}'`
		y=`cat /tmp/jdfmt2|grep $i|awk '{print $12}'`
	fi
	printf "%-6s %-10s %-10s %-10s \n" "$i" "$x" "$y" "(info: $z )" 
done

#rm /tmp/jdfmt
#rm /tmp/jdfmt2
#rm /tmp/jdfmt3

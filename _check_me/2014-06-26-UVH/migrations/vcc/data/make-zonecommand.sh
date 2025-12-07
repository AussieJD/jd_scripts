#!/bin/sh
#
# create vcc zone command files

BASE1=/UVH/stuff/migration-notes/vcc/scripts
BASE2=/UVH/stuff/rsync-scripts/vcc/
FILE1=zone-create.aubwsacc

for i in 003 004 005 006 007 008 015 016 017 018
 do
echo "create -t SUNWsolaris8
set zonepath=/zones/aubwsacc$i
set autoboot=false
set bootargs=\"-m verbose\"" > $BASE1/$FILE1$i

cat $BASE1/jd* | grep \^${i} | grep -v "@" | grep -v "$i root" | while read line 
 do
	sp=`echo $line| awk '{print $2}'`	
	zp=`echo $line| awk '{print $8}'`	
	echo "add fs
set dir=$zp
set special=/zones/fs/aubwsacc$i/$sp
set type=lofs
end" >> $BASE1/$FILE1$i
	done

cat $i.network >> $BASE1/$FILE1$i

echo "set hostid=`cat $BASE1/$i.hostid`" >> $BASE1/$FILE1$i
echo "verify"  >> $BASE1/$FILE1$i
echo "commit" >> $BASE1/$FILE1$i
done



# The End

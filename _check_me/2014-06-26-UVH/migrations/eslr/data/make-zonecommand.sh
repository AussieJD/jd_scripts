#!/bin/sh
#
# create gipw zone command files

BASE1=/UVH/stuff/migration-notes/eslr/scripts
BASE2=/UVH/stuff/rsync-scripts/eslr
FILE1=zone-create
LIST="aubwsgipw100 aubwsgipw101"

for i in $LIST
 do
	cat $BASE1/$i.top > $BASE1/$FILE1.$i

	cat $BASE2/uvh-eslr-data-sizes.out | grep $i | grep -v "$i root" | while read line 
	 do
		sp=`echo $line| awk '{print $3}'`	
		zp=`echo $line| awk '{print $4}'`	
		echo "add fs
set dir=$zp
set special=/zones/fs/$i/$sp
set type=lofs
end" >> $BASE1/$FILE1.$i
	done

	echo "set hostid=`cat $BASE1/$i.hostid`" >> $BASE1/$FILE1.$i
	echo "verify"  >> $BASE1/$FILE1.$i
	echo "commit" >> $BASE1/$FILE1.$i
done



# The End

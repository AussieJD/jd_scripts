#!/bin/sh
#
# Script:	signature.sh
#
# Script to modify .signature file with a daily message, extracted
# from a messages file
#
# Created:	Jan 1999	b.james
#
# Modifications:
#
# dd mmm yyyy	A.Person	Detail....
#
# 15 jan 1999	j.driscoll	revised script for j.driscoll
#				added *smart* message file handling
#
#
#	Actions:	- calculate no. of records in message file
#			- set this to counter MAX
#			- extract line from messages file
#			- progress counter by one (if counter=MAX
#			  then reset counter to 1) 
#			- create new .signaure file with extracted line 
#
##### VARIABLES #######
#
HOME2=$HOME/signature.stuff
cfile=$HOME2/signature.body		# main *unchanging* signature
mfile=$HOME2/signature.message.list	# messages file
xfile=$HOME2/signature.message.number	# message counters
sfile=$HOME/.signature			# signature file
#
##### calculate no. of records in message file ######
#
NUM=0
for i in `cat $mfile | awk '{ print $1 }' `
do
NUM=`expr $NUM + 1`
done
#
#### pick line number and increment counter ######
#
COUNT=`cat $xfile`
if [ $COUNT = $NUM ]; then
echo 1 > $xfile
else COUNT=`expr $COUNT + 1`
echo $COUNT > $xfile
fi

##### Select message and create .signature file
#
message=`head -$COUNT $mfile | tail -1 `
cat $cfile > $sfile
echo "JD's thought #$COUNT" >> $sfile
echo "$message" >> $sfile
echo "------------------------------------------------------------------" >>$sfile
#
#


#
# The End!
#

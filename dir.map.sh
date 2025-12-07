#!/bin/ksh
#
# Script:	interrogate a folder and feedback stats to user
#		- 5 largest files
#		- 5 oldest files
#		- 5 largest folders
#
# Created:	j.driscoll	12-Nov-2001
#
#
## Variables #################
#
#sort1=`sort -k 1,1n`
start=`pwd`
tempfile=/tmp/sort.out
tempfile1=/tmp/sort-files.out
tempfile2=/tmp/sort-folders.out
#sample=5
#
## Script ####################
#
clear
echo "---------------------------------------------------
\tManage folders
\nEnter list length..>\c"
read sample
echo "starting from $start"
[ $tempfile ] && rm $tempfile
[ $tempfile1 ] && rm $tempfile1
[ $tempfile2 ] && rm $tempfile2
find . >> $tempfile
for i in `cat $tempfile`;do [ ! -d $i ] && echo $i >> $tempfile1 ;done
for i in `cat $tempfile`;do [ -d $i ] && echo $i >> $tempfile2 ;done

echo "$sample largest files\n------------------"
du -ks `cat $tempfile1` | sort -k 1,1n | tail -$sample
echo "$sample smallest files\n------------------"
du -ks `cat $tempfile1` | sort -k 1,1n | head -$sample

echo "$sample largest folders\n------------------"
du -ks `cat $tempfile2` | sort -k 1,1n | tail -$sample
echo "$sample smallest folders\n------------------"
du -ks `cat $tempfile2` | sort -k 1,1n | head -$sample


#
## The End ###################

#!/bin/ksh
#
# Usage: move a file/directory - to a different directory - using tar
#
clear
echo " Move a file or directory using tar (to a different directory)"
echo "what do you want to move (whole path) ..>\c"
read SRC
#SRC=/export/home/wabi.master
echo "where do you want to move it to (whole path to new folder) ..>\c"
read DEST
#DEST=/export/home/peterg
echo "\n\tWould be moving $SRC to $DEST \n\tIs this ok (y)..>\c"
read ans
if [ "$ans" -eq "" ];then ans2=y;fi
if [ "$ans2" -eq "y" ];then tar cvfp - $SRC | (cd $DEST; tar xf - );else echo ..quiting;sleep 1;fi

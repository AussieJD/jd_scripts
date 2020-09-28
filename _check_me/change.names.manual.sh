# j.driscoll  11.5.98  ksh
#
# Usage: append all files in a directory with a *prompted* item
#
# This script will append all files in a directory with a 
# prompted item. 
clear
echo Brief:	make a copy of files, then append/prepend the copies
echo creating temporary files .. please wait
mkdir new
cd new
cp ../* . 
pwd
echo " Enter text to add to start of names (ie. start. )...\c\n"
read START
echo " Enter text to add at end of names (ie. .end) ... \c\n"
read END

for i in * ; do mv ${i} ${START}${i}$END ; done
echo " type ' ls -al new ' to see new files"







# j.driscoll  ksh 14-may-1998
#
# Usage: copy a directory: same dir, diff name: diff dir, diff name: diff dir, same name 
# this script copies a directory
#   - to the same directory -> different name
#   - to a different directory -> same name
#   - to a different directory -> different name
#

#### variables #####
NAME				# the name of the directory to be copied
HERE=`pwd`			# current directory
THERE=$HERE

#### script - try not to edit below here ####

clear
echo "\n This script copies a directory to the current directory or elsewhere"
echo " NOTE: the name MUST be changed.\n"
echo " ========================================================= "
echo "\n The contents of the current directory [ $HERE ] : "
ls -l
echo " \n Please enter the name of the directory to be copied..>\t\c"
read NAME
echo " \n What do you want to call the copy..[ $NAME ] >\t\c"
read NEWNAME
#echo " \n Where do you want to put the copy..[ $HERE ] >\t\c"
#read THERE
echo " $NAME  $HERE  $THERE $NAME $NEWNAME "
tar cvfr - ${NAME} | (cd /tmp;tar xvf -)
mv /tmp/${NAME} /tmp/${NEWNAME}
#tar cvfr - /tmp/${NEWNAME} |(cd $THERE;tar xvf -)
cd /tmp
tar cvfr - ${NEWNAME} |(cd $HERE;tar xvf -)
#rm -r /tmp/${NEWNAME}
echo "\n NOTE: THERE IS A COPY OF THIS DIR IN /tmp - remember to delete..!!"

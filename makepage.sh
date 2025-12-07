# This Script is designed to creat a simple web page 
#   It uses a Start.html file and an End.html file and
#   inserts selected text into the middle  - hence, Web Page...

BASEDIR=/home/staff/jon/jdnet
STARTPAGE=/home/staff/jon/jdnet/jdstart.html
ENDPAGE=/home/staff/jon/jdnet/jdend.html
DATE=`date +%c`

cd $BASEDIR
echo "\n" 
echo "************************************************************" 
echo "\n" 

echo "This script creates a simple web HTML page using a text file"
echo "\n" 
echo "...please enter the path and name to the text file...: "
echo "ie.  /home/staff/jon/contacts.jd " 
echo "     /home/staff/jon/modloan.jd "
echo "\t\t\t\t\t==> \c"
read INPUTFILE

echo "\n" 
echo "Enter the name for the *new* HTML page  ie. jdpage ..."
echo "\t\t contacts "
echo "\t\t modloansnew "
echo "\t\t\t\t\t==> \c"
read PAGENAME
echo "\n\n" 
cat $STARTPAGE > ${BASEDIR}/${PAGENAME}.html
echo " Page last updated: ${DATE}" >> ${BASEDIR}/${PAGENAME}.html
echo "\n" >> ${BASEDIR}/${PAGENAME}.html
cat $INPUTFILE >> ${BASEDIR}/${PAGENAME}.html
cat $ENDPAGE >> ${PAGENAME}.html 
chgrp staff ${PAGENAME}.html
chmod 775 ${PAGENAME}.html


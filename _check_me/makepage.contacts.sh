# This Script is designed to creat a simple web page 
#   It uses a Start.html file and an End.html file and
#   inserts selected text into the middle  - hence, Web Page...

BASEDIR=/home/staff/jon/jdnet
STARTPAGE=/home/staff/jon/jdnet/jdstart.html
ENDPAGE=/home/staff/jon/jdnet/jdend.html
DATE=`date +%c`

#This script creates a simple web HTML page using a text file"

INPUTFILE=/home/staff/jon/contacts.jd
PAGENAME=contacts

cat $STARTPAGE > ${BASEDIR}/${PAGENAME}.html
echo " Page last updated: ${DATE}" >> ${BASEDIR}/${PAGENAME}.html
echo "\n" >> ${BASEDIR}/${PAGENAME}.html
cat $INPUTFILE >> ${BASEDIR}/${PAGENAME}.html
cat $ENDPAGE >> ${PAGENAME}.html 
chgrp staff ${PAGENAME}.html
chmod 775 ${PAGENAME}.html


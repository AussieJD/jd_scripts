# j.driscoll  11.5.98  ksh
#
# Usage: append *selected* mail files with a *prompted* date stamp
#
# This script will append specified Mail files with a prompted date stamp. 


echo " Creating temp directory.... "
cd /home/staff/jon/Mail/general
mkdir tempmail
cd tempmail
cp ../* . 
echo " Moving into tempmail directory " ;pwd
echo " Enter date stamp for files .(ie. ' .05.98 ') ... \c\n"
read END
echo " Appending files with '$END' - <CTRL+C> to quit and start again..<ENTER> to continue " 
read WAIT
echo "  ....appending files - please wait.. "

for i in * ; do mv ${i} ${START}${i}$END ; done
#echo " type ' ls -al tempmail ' to see new files"
echo " Moving files to /Mail/old - please wait.. "
cp * ../../old
echo "\n"
ls
cd ..
echo " Temp directory being removed - please wait.. "
tar cf - tempmail |(cd /tmp;tar xf -)
rm -r tempmail
echo " Check the file list \n"
ls -C ../old | more
echo " Is it OK to remove the original files <ENTER> = Yes, <CTRL+C> = No "
read WAIT
echo " If No, the files will need to be handled manually.... "
echo " ...removing the following files ...... \n"
ls -1 |more
echo " - please wait"
rm *
#echo " Creating new Mail files - please wait"
echo " The following Mail/general mailboxes need to be created . "
echo " ibaks \n customer \n done \n info \n jumpstarts \n loanbookings \n may-read \n new \n pc-stuff \n private \n SE-stuff \n sent.mail \n "

echo " If this really stuffs up, a copy of the files is in the /tmp directory..."
echo " THE END ! "


# this script will prompt for a string to insert into a 'find'
#
# jon driscoll	2.4.1998
#
echo " This script will do a 'find . -name '*XXX*' -print'"
echo "\n\n Please enter string to search for..."
read SEARCH
find . -name "*${SEARCH}*" -print	
#echo $SEARCH



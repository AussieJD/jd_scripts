##### shell script that starts an Xterm to 'vi' named file  ###
#############################################################################
#
# Usage: starts an Xterm to 'vi' editing JDs Contacts (with Name)
#
#
TITLE=JDsContacts 
ICONTAG=jdscontacts
FILETOEDIT=/home/staff/jon/contacts.jd
#
#
######## do not edit below this line ##################

xterm -geometry 125 -T $TITLE -n $ICONTAG -sb  -bg gray -e vi $FILETOEDIT 
/home/staff/jon/bin/makepage.contacts.sh


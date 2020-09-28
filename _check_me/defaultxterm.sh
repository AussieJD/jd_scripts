##### shell script that starts an Xterm to 'vi' named file  ###
#############################################################################
# Usage: starts an Xterm to 'vi' named file (in this case, contacts.jd)
cd $HOME
TITLE=JDsContacts 
ICONTAG=jdscontacts
FILETOEDIT=contacts.jd


######## do not edit below this line ##################

xterm -geometry 125 -T $TITLE -n $ICONTAG -sb  -bg gray -e vi $FILETOEDIT &



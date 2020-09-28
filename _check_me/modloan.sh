##### shell script that starts an Xterm to 'vi' named file  ###
#############################################################################


TITLE=Loanmods
ICONTAG=loanmods
FILETOEDIT=/home/staff/jon/modloan.jd


######## do not edit below this line ##################

xterm -geometry 125 -T $TITLE -n $ICONTAG -sb  -bg gray -e vi ${FILETOEDIT} 
/home/staff/jon/bin/makepage.modloan.sh


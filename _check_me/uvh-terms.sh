#!/bin/bash
#
PWD1=`pwd`
#[ ! $1 ] && echo "usage: $0 {right|below}";exit 0
echo var=$1
COUNT=1

# max width
WM=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) -root | grep "^  Width" | awk '{print $2}'`
HM=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) -root | grep "^  Height" | awk '{print $2}'`

# geom f1
G1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  -geo"|awk -F"x" '{print $1}'|awk '{print $2}'`
# geom f2
G2=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  -geo"|awk -F"x" '{print $2}'|awk -F"+" '{print $1}'`
# geom f3
G3=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  -geo"|awk -F"+" '{print $2}'`
# geom f4
G4=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  -geo"|awk -F"+" '{print $3}'`
# width
W1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Width" | awk '{print $2}'`
# height
H1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Height" | awk '{print $2}'`
# relative upper left X
RX1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Relative upper-left X" | awk '{print $4}'`
# relative upper left Y
RY1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Relative upper-left Y" | awk '{print $4}'`
# absolute upper left X
AX1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Absolute upper-left X" | awk '{print $4}'`
# absolute upper left Y
AY1=`xwininfo -id $(xprop -root | awk '/_NET_ACTIVE_WINDOW\(WINDOW\)/{print $NF}' 2> /dev/null) | grep "^  Absolute upper-left Y" | awk '{print $4}'`


# G1xG2+G3+G4

clear
echo max=$WM G1=$G1 G2=$G2 G3=$G3 G4=$G4 width=$W1 height=$H1 X=$RX1 Y=$RY1

if [ "$1" = "below" ] ; then 
# below
# G1xG2+G3+(G2+H1+RX1+RY1)

G5=`echo "${G4}+$H1+$RX1+$RY1"|bc`
CHECK=`echo "${G5}+${AY1}+${G5}|bc`
echo "check = $CHECK"
[ "$CHECK" > "$HM" ] && echo ".. would be too wide to fit. Reduce size / and / or move left"\;exit0
echo "... running below"
echo "current: ${G1}x${G2}+${G3}+${G4}"
echo "    new: ${G1}x${G2}+${G3}+${G5}"

gnome-terminal --geometry ${G1}x${G2}+${G3}+${G5}

elif [ "$1" = "right" ] ; then
# right
# G1xG2+(G3+W1+RX1+RX1)+G4

G6=`echo "${G3}+${W1}+${RX1}+${RX1}"|bc`
CHECK=`echo "${G6}+${AX1}+${G6}|bc`
echo "check = $CHECK"
[ "$CHECK" > "$WM" ] && echo ".. would be too wide to fit. Reduce size / and / or move left"\;exit0
echo "... running right (G6=$G6)"
echo "current: ${G1}x${G2}+${G3}+${G4}"
echo "    new: ${G1}x${G2}+${G6}+${G4}"
gnome-terminal --geometry ${G1}x${G2}+${G6}+${G4}

else
	echo "usage: $0 {right|below}";exit 0
fi		
	

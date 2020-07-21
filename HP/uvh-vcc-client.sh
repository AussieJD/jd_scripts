#!/bin/bash
#
# open VNC session to the UVH (requires HP VPN and SSN / JSAM ) 
#
# Usage:	uvh-vcc-client.sh
#
BASE=~/scripts/dropbox-scripts/HP
VNC02FILE="$BASE/vcc002.vncloc"

clear
echo "Select observe quality:
1)	Wire
2)	Low (default)
3)	Med
4)	High"
echo -n "5)	Very High 		Select: [2]>"
read NUM
[ ! $NUM ] && NUM=2
echo "Select: 
1)	VNC-UVH-002"
echo -n "2)	UVH-VNC-005	 		Select: "
read IMAC
case $IMAC in

	1 ) echo "setting observe to quality $NUM, running screen sharing to VNC 002"
	defaults write com.apple.ScreenSharing controlObserveQuality $NUM 
	open $VNC02FILE
	;;

	2 ) echo "setting observe to quality $NUM, running screen sharing to VNC 005"
	defaults write com.apple.ScreenSharing controlObserveQuality $NUM 
	open $VNC05FILE 
	;;

esac
	

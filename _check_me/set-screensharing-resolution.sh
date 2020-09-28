#!/bin/bash
#
# set the "observe" level for screen sharing
#
# Usage: set-screensharing-resolution.sh <machine>  <number from 1 to 5>
#
BASE=~/scripts/dropbox-scripts
CHRISFILE="$BASE/screen-sharing-chris-imac.vncloc"
JDFILE="$BASE/screen-sharing-imac27.vncloc"
MBFILE="$BASE/screen-sharing-macbook.vnloc"
AIRFILE="$BASE/screen-sharing-air.vnloc"

clear
echo "Select observe quality:
1)	Wire
2)	Low (default)
3)	Med
4)	High"
echo -n "5)	Very High 		Select: [2]>"
read NUM
[ ! $NUM ] && NUM=2
echo "Select iMac:
1)	Chris
2)	JD"
echo -n "3)	Macbook	 		Select: "
read IMAC
case $IMAC in

	1 ) echo "setting observe to quality $NUM, running screen sharing to Chris's iMac"
	defaults write com.apple.ScreenSharing controlObserveQuality $NUM 
	open $CHRISFILE
	;;

	2 ) echo "setting observe to quality $NUM, running screen sharing to JD's iMac"
	defaults write com.apple.ScreenSharing controlObserveQuality $NUM 
	open $JDFILE 
	;;

	3 ) echo "setting observe to quality $NUM, running screen sharing to JD's iMac"
	defaults write com.apple.ScreenSharing controlObserveQuality $NUM 
	open $MBFILE 
	;;

esac
	

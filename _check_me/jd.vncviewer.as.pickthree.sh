#!/bin/bash

MYHOME="/Volumes/data/Users/jon"
MYVNCVIEWER="/Applications/VNC\ Viewer.app/Contents/MacOS/vncviewer"

OTHER_DOT_VNC="$MYHOME/.vnc.pickthree"

ORIG_DOT_VNC="$MYHOME/.vnc"
ORIG_SAVED_STATE_BASE="$MYHOME/Library/Saved\ Application\ State/"
ORIG_SAVED_STATE_FOLDER="com.realvnc.vncviewer.savedState"

# Script
mv $ORIG_DOT_VNC $MYHOME/.vnc.orig
#mv $ORIG_SAVED_STATE_BASE/$ORIG_SAVED_STATE_FOLDER $ORIG_SAVED_STATE_BASE/$ORIG_SAVED_STATE_FOLDER.orig 
cp -R $OTHER_DOT_VNC $ORIG_DOT_VNC
eval $MYVNCVIEWER
rm -r  $ORIG_DOT_VNC
mv $MYHOME/.vnc.orig $ORIG_DOT_VNC

# The End!

#!/bin/sh

###
## xtermrand
##
## Pops up xterms with random foreground colors
## based on time of day.
##
## Usage: xtermrand 
##
## Submitter:  James Falkner
## Author:     James Falkner
## Submitter Email: schtool@yahoo.com

COLORS="lightblue white green yellow red orange pink grey"
COLOR_LEN=8

PICK=`expr \`date '+%S'\` % ${COLOR_LEN}`

PICK=`expr $PICK + 1`
EXECLINE="echo $COLORS|awk '{print \$${PICK}}'"
COLOR=`eval $EXECLINE`

if [ "$1" = "-s" ] ; then
SMALL="-fn 5x7"
fi

xterm ${SMALL} -fg ${COLOR} -bg black -sb -sl 2000 -title `uname -n`:`/usr/ucb/whoami` &

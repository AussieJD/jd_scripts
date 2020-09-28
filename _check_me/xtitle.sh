#!/bin/ksh

###
## xtitle
##
## Convenience script to change the title of the
## current xterm window.
##
## Usage: changes title of current xterm window xtitle <new_title>
##
## Submitter:  James Falkner 
## Author:     James Falkner
## Submitter Email: schtool@yahoo.com

print -n "0;${1}"

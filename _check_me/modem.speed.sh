#!/bin/ksh
#
# Usage: copy a file of known size over the modem and time it
#
mkfile 10k /tmp/10k.file
date1=`date`
tar cvf - /tmp/10k.file | rsh blackbird cd /tmp;tar xvf - 
date2=`date`
echo start=$date1
echo end=$date2
rsh blackbird rm /tmp/10k.file
rm /tmp/10k.file

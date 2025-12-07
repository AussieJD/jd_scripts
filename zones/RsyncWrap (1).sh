#!/bin/sh
Rsync=/usr/local/bin/rsync
Ssh=/usr/bin/ssh
Source=adl0507:/u01/
Target=/u01/
Log=/var/tmp/syncer.log
ExitHour=13     # Set it to run for no more than 24 hours 

# This rsync copies data from $Source to this host:$Target
echo "\n `date` \n" > $Log

Hour="`date '+ %H'`"

while [ ! "$Hour" -eq "$ExitHour" ]  ; do
   if [ ! "`ps -ef | grep rsync | grep -v grep`" ] ; then
      echo "\n `date` \n" > $Log
      $Rsync -auvz --rsh=$Ssh --rsync-path=$Rsync  $Source $Target >> $Log 2>&1 
      sleep 80
      Hour="`date '+ %H'`"
   fi
done

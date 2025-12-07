#!/bin/sh
#
# Script to shut down and restart VCC databases on zones aubwsacc006 and aubwsacc007
#
# Comments:	- intended to be able to run separately, or in conjunction with UVH platforms scripts 
#		   to move DB instances between aubwsacc006 and aubwsacc007
#

#
## Variables

ORACLE_SID=$1; export ORACLE_SID
ORATAB=/var/opt/oracle/oratab; export ORATAB
ORACLE_HOME=`cat $ORATAB | grep $ORACLE_SID | awk -F: '{print $2}' -`; export ORACLE_HOME
PATH=$ORACLE_HOME/bin:$PATH:; export PATH

#
## Script

## start


## stop
#stop listener

lsnrctl stop LISTENER_${ORACLE_SID}
sqlplus /nolog <<EOFSQL
connect / as sysdba
shutdown abort
startup restrict
shutdown immediate
exit
EOFSQL

#wait for completion

#unmount disks
#release network connections


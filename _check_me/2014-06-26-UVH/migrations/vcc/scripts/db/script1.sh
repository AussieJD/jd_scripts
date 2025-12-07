# Run as the oracle user - su - oracle
# the connect / as sysdba relies on oracle os user authentication

### Shutdown database and listener
### database (SID) variable $1 should be APPAMS1 or APPEMS1

#    oracle sid is the database
ORACLE_SID=$1; export ORACLE_SID
#    oratab has entries for each database and Oracle home (executables)
ORATAB=/var/opt/oracle/oratab; export ORATAB
#    get the oracle home from oratab
ORACLE_HOME=`cat $ORATAB | grep $ORACLE_SID | awk -F: '{print $2}' -`; export ORACLE_HOME
#    Put $ORACLE_HOME/bin into PATH and export. Will allow sqlplus / lsnrctl to be found
PATH=$ORACLE_HOME/bin:$PATH:; export PATH
## LD_LIBRARY_PATH=$PATH:${ORACLE_HOME}/lib ; export LD_LIBRARY_PATH
#    Stop listener
lsnrctl stop LISTENER_${ORACLE_SID}
#    Shutdown database  
sqlplus /nolog <<EOFSQL
connect / as sysdba
shutdown abort
startup restrict
shutdown immediate
exit
EOFSQL


### Startup database and listener
### database (SID) variable $1 should be APPAMS1 or APPEMS1

#    oracle sid is the database (APPAMS1 or APPEMS1)
ORACLE_SID=$1; export ORACLE_SID
#    oratab has entries for each database and Oracle home (executables)
ORATAB=/var/opt/oracle/oratab; export ORATAB
#    get the oracle home from oratab
ORACLE_HOME=`cat $ORATAB | grep $ORACLE_SID | awk -F: '{print $2}' -`; export ORACLE_HOME
#    Put $ORACLE_HOME/bin into PATH and export. Will allow sqlplus / lsnrctl to be found
PATH=$ORACLE_HOME/bin:$PATH:; export PATH
## LD_LIBRARY_PATH=$PATH:${ORACLE_HOME}/lib ; export LD_LIBRARY_PATH
sqlplus /nolog <<EOFSQL
connect / as sysdba
startup
exit
EOFSQL

# testing for live database process on ORACLE_SID
pmon=`ps -ef | egrep pmon_$ORACLE_SID  | grep -v grep`
if [ "$pmon" != "" ];
then
    STATUS="-1"
    echo "Database \"${ORACLE_SID}\" already started."
fi

# The End!

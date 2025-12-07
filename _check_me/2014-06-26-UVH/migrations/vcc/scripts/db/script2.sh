aubwsacc006:/opt/oracle/local/bin> cat dbora
#!/sbin/sh
#
#    dbora - server stop start script for Oracle databases
#    usage - dbora [start | stop]
#    normally executed from /etc/init.d by root
#    Logs to Oracle home startup log
#
EMAIL_FILE=/opt/oracle/DBMONITOR/parm/dba_email.txt
ORA_HOME=/1a/opt/oracle/product/9.2.0.1.0
ORA_OWNER=oracle
LOG=db_start_stop.log
# LOG=${ORA_HOME}/startup.log
if [ ! -f $LOG ];
then
    touch ${LOG}
    chmod a+r ${LOG}
fi


echo "                            "  >> ${LOG} 2>&1
echo "####################################################"  >> ${LOG} 2>&1
echo "Start of /etc/init.d/dbora  "  >> ${LOG} 2>&1
date  >> ${LOG} 2>&1

echo "     ps -ef | egrep 'pmon|inher' before $1"     >>  ${LOG}
ps -ef | egrep 'pmon|inher' | grep -v egrep           >>  ${LOG}

#    Either start or stop the databases depending on the input parameter

case "$1" in
        'start')
           # Check that the database stop / start script exists
           if [ ! -f $ORA_HOME/bin/dbstart -o ! -d $ORA_HOME ]; then
              echo "Oracle Startup: cannot start"  >> ${LOG} 2>&1
              exit
           fi

           # Start the Oracle database:
           echo "${0}: Starting Up" >> ${LOG}
           date >> ${LOG}
           ## su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl start "  >> ${LOG} 2>&1
           #  For the listeners may need to set oraenv to databases
           su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl start LISTENER_APPEMS1"  >> ${LOG} 2>&1
##         $ORA_HOME/bin/lsnrctl start LISTENER_APPEMS1  >> ${LOG} 2>&1
           su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl start LISTENER_APPAMS1"  >> ${LOG} 2>&1
##         $ORA_HOME/bin/lsnrctl start LISTENER_APPAMS1  >> ${LOG} 2>&1
           su - $ORA_OWNER -c "$ORA_HOME/bin/dbstart"  >> ${LOG} 2>&1
##         $ORA_HOME/bin/dbstart  >> ${LOG} 2>&1
         ;;

        'stop')
           if [ ! -f $ORA_HOME/bin/dbshut -o ! -d $ORA_HOME ]; then
              echo "Oracle Shutdown: cannot shutdown"  >> ${LOG} 2>&1
              exit
           fi

           # Stop the Oracle databse:
           echo "${0}: Shutting Down" >> ${LOG}
           date >> ${LOG}
           su - $ORA_OWNER -c $ORA_HOME/bin/dbshut   >> ${LOG} 2>&1
##         $ORA_HOME/bin/dbshut   >> ${LOG} 2>&1
           # For the listeners may need to set oraenv to databases
           su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl stop LISTENER_APPEMS1"  >> ${LOG} 2>&1
##         $ORA_HOME/bin/lsnrctl stop LISTENER_APPEMS1  >> ${LOG} 2>&1
           su - $ORA_OWNER -c "$ORA_HOME/bin/lsnrctl stop LISTENER_APPAMS1"  >> ${LOG} 2>&1
##         $ORA_HOME/bin/lsnrctl stop LISTENER_APPAMS1  >> ${LOG} 2>&1
         ;;
esac

echo "     ps -ef | egrep 'pmon|inher' after $1"     >>  ${LOG}
ps -ef | egrep 'pmon|inher' | grep -v egrep          >>  ${LOG}

echo "End of /etc/init.d/dbora  "  >> ${LOG} 2>&1
date  >> ${LOG} 2>&1
echo "####################################################"  >> ${LOG} 2>&1
echo "                            "  >> ${LOG} 2>&1

# Email notification that server stop / start script has been run
tail -200 ${LOG} | mailx -s "`hostname`: $0 $1 executed" `cat $EMAIL_FILE`

exit

# The End!

#!/bin/bash
#set -x

# ANSI escape sequence (echo -e = enables it)
# -- Bold text: \033[1m ... \033[0m
# \033 is escape
# [1 turns ON bold atribute, [0 turns it OFF, m terminates each escape sequence
# -- Colors
# \E[ begins escape sequence
# COLOR         FOREGROUND      BACKGROUND
# black         30              40
# red           31              41
# green         32              42
# yellow        33              43
# blue          34              44
# magenta       35              45
# cyan          36              46
# white         37              47
# Restore terminal settings to normal: echo -ne "\E[0m"
# Restore terminal settings to normal: tput sgr0

# Check if user is root
if [ `/usr/bin/id | awk '{print $1}' | cut -d= -f2 | cut -d\( -f1` != 0 ]
then
        echo ; echo Sorry, you have to be root to run this script. ; echo
        exit 1
fi

# Variable
GREP=/usr/sfw/bin/gegrep

if [ "`fcinfo hba-port`" = "No Adapters Found." ]
then
        echo ; echo -e "\033[1m \E[35;40m There is no installed FC HBA on this system! \033[0m" ; echo -ne "\E[0m"
        echo ; exit 1
else
        FCNUMBER=`fcinfo hba-port | ${GREP} "HBA Port WWN" | wc -l | nawk '{print $1}'`
        echo
        echo -e  There are "\033[1m \E[33;40m ${FCNUMBER} FC HBA(s) \033[0m" in the system. ; echo -ne "\E[0m"
fi

FCWWN=`fcinfo hba-port | ${GREP} HBA | nawk '{print $4}'`

for i in ${FCWWN}
do

        FCSTATE=`fcinfo hba-port ${i} | grep State: | nawk '{print $2}'`

        if [ ${FCSTATE} = online ]
        then
                # port is online
                echo
                echo -e The FC Port WWN "\033[1m \E[36;40m ${i} \033[0m is \033[1m \E[37;42m ${FCSTATE} \033[0m"
                echo -ne "\E[0m"

                printf "################################################################################## \n"
                printf "%-18s %9s %18s %20s \n" "FC HBA (Host)" "Path" "Remote" "LUN:"
                printf "%-18s %9s %18s %20s \n" "Port WWN" "Channel" "WWN" " "
                printf "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- \n"

                /usr/sbin/mpathadm list initiator-port | ${GREP} ${i} > /dev/null
                if [ "$?" != "0" ]
                then
                        echo There is no multi path for this port.
                        exit 1
                fi

                FCREMOTE=`fcinfo remote-port -p ${i} | ${GREP} Remote | nawk '{print $4}'`

                printf "%-18s \n" "${i}"

                for j in ${FCREMOTE}
                do
                        CHANNEL=`cfgadm -al | ${GREP} -v unconfigured | ${GREP} ${j} |nawk -F:: '{print $1}'`
                        LUNNAME=`/usr/sbin/luxadm display ${j} | ${GREP} /dev/rdsk | ${GREP} -i -v DEVICE`
                        if [ "$?" != "0" ]
                        then
                                echo -e "\033[1m \E[35;40m Cannot display device on Remote Port WWN ${j} \033[0m"
                                echo -ne "\E[0m"
                        else
                                PRODUCT=`/usr/sbin/luxadm display ${j} | ${GREP} Product | nawk -F: '{print $2}'`
                                CAPACITY=`/usr/sbin/luxadm display ${j} | ${GREP} capacity | nawk -F: '{print $2}'`
                                printf "%27s %18s %30s \n" "${CHANNEL}" "${j}" "${LUNNAME}"
                                printf "%51s %20s \n" "${PRODUCT}" "${CAPACITY}"
                        fi
                done

        else
                # port if offline
                echo -e The FC Port WWN "\033[1m \E[36;40m ${i} \033[0m is \033[1m \E[37;41m ${FCSTATE} \033[0m"
                echo -ne "\E[0m"
        fi

done

exit 0

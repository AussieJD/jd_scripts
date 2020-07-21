################################################################################
# 
# SysChk - System Status Check
#
# Author     : Peter Magee (pmdba@aol.com)
#
# Functions  : log_chk   - Writes n lines of log files to stdout
#              link_info - Gets property values for network interfaces
#              link_chk  - Writes interpreted network interface values to stdout
#              meta_chk  - Writes formated metadevice information to stdout
#              main      - Writes formated system status information to stdout
#
# Description: SysChk generates as complete a picture of current system status
#              as possible, including uptime, basic system config, cpu status,
#              reboot history, current and past users, system and security logs,
#              running processes, disk, array, and file system status, swap
#              space status, network interface status, and current network
#              connections.
#
################################################################################

################################################################################
# log_chk ()
#
# Called By  : Main
# Calls      : n/a
# Inputs     : $1 - Log file name (e.g. /var/adm/messages)
# Returns    : Writes contents of log files to stdout
#
# Description: Checks sequential log files for the last X lines of entries. If
# there are less than X lines in the most recent log, get the remaining lines 
# from the first archived log. Default number of entries to retrieve is 20.
#
################################################################################

log_chk () {

  # Set number of lines to be returned from log files

  NRLINES="20"

  # Determine how many lines are in most recent log

  MSGLEN=`cat "$1" | wc -l | awk '{print $1}'`

  # If less than NRLINES found, get remaining lines from archived log 

  if [ "$MSGLEN" -lt "$NRLINES" ]; then
    OLDLOG="$1".0

    # Calculate lines needed from archive log

    OFFSET=`expr "$NRLINES" - "$MSGLEN"`

    # List log file names

    ls -l "$1" "$OLDLOG"
    echo

    # List log contents

    tail -"$OFFSET" "$OLDLOG"
    tail -"$MSGLEN" "$1"

  # If NRLINES available in most recent log file, read from there.

  else

    # List log file name

    ls -l "$1"
    echo

    # List log contents

    tail -"$NRLINES" "$1"
  fi 
}

################################################################################
# link_info ()
#
# Called By  : link_chk ()
# Calls      : n/a
# Inputs     : $1 - device name (e.g. /dev/eri)
#              $2 - property name (e.g. link_speed)
# Returns    : 0 or 1, meaning is dependant on specific property
#
# Description: Checks the ndd database and retrieves properties of network
#              interfaces.
#
################################################################################

link_info () {

  # Get value of interface property from ndd database

  LINKINFO=`/usr/sbin/ndd -get "$1" "$2"`

  # Return "1" if value is "1", else return "0"

  if [ "$LINKINFO" -eq "1" ]; then
    return 1
  else
    return 0
  fi
}

################################################################################
# link_chk ()
#
# Called By  : Main
# Calls      : link_info ()
# Inputs     : $1 - Interface device name (e.g. eri)
#              $2 - Interface name (e.g. eri0)
# Returns    : Writes network interface properties to stdout
#
# Description: Generates information on network interface properties and 
#              interprets returns from the link_info function.
#
################################################################################

link_chk () {

  # Get info on interface speed. Value of 1=100Mbit, 0=10Mbit

  if link_info "/dev/$1" "link_speed"; then
    echo "$2 link speed    : 10 Mbit"
  else
    echo "$2 link speed    : 100 Mbit"
  fi

  # Get info on interface mode. Value of 1=Full Duplex, 0=Half Duplex

  if link_info "/dev/$1" "link_mode"; then
    echo "$2 link mode     : Half Duplex"
  else
    echo "$2 link mode     : Full Duplex"
  fi

  # Get info on interface negiation. Value of 1=Autonegotiate, 0=Fixed

  if link_info "/dev/$1" "adv_autoneg_cap"; then
    echo "$2 autonegotiate : Off"
  else
    echo "$2 autonegotiate : On"
  fi
}

################################################################################
# meta_chk ()
#
# Called By  : Main
# Calls      : n/a
# Inputs     : n/a
# Returns    : Writes formatted status of metadevices to stdout
#
# Description: Uses output from the metastat command to create a formatted
#              tree describing device names, mount points, utilization, status,
#              and relationship to other devices.
#
################################################################################

meta_chk () {

  # Run metastat and parse the output

  LINE='0'
  eval "/usr/sbin/metastat" | while read line
  do
    set -f $line

    # Check first character of first column to determine which row of output 
    # we are on

    CHKD=`echo $1 | awk '{print substr($1,1,1)}'`

    # If this is a new meta device, then print the previous metadevice and 
    # collect new data

    if [ "$CHKD" = "d" ]; then
      if [ $LINE != "0" ]; then
        echo $DEVNAME $DISKDEV $MOUNTPT $SIZE $USED $STATE $COMMENT | \
          awk '{printf"%-11s %-11s %-12s %-3s %-3s %-5s %-11s %s %s %s\n", \
           $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | sed s/-/' '/g 
      fi

      # Collect device name, mount point, usage, and comment data

      COMMENT=`echo $2 $3 $4`

      DEVNAME=`echo $1 | sed s/://`
      CHKC=`echo $COMMENT | awk '{print substr($1,1,3)}'`
      if [ "$CHKC" != "Sub" ] && [ $LINE != "0" ]; then
        echo " "
      fi

      MOUNTCK1=`swap -l | grep $DEVNAME`
      if [ -n "$MOUNTCK1" ]; then
        MOUNTPT='swap'
        USED='N/A'
      else
        MOUNTCK2=`grep $DEVNAME /etc/vfstab`
        if [ -n "$MOUNTCK2" ]; then
          MOUNTPT=`grep $DEVNAME /etc/vfstab | awk '{print $3}'`
          USED=`df -k $MOUNTPT | grep $DEVNAME | awk '{print $5}'`
        fi
      fi

      if [ -n $MOUNTPT ]; then
        COMMENT="$COMMENT of $MOUNTPT"
      fi

      DISKDEV='-'
      SIZE='- -'
      STATE='-'
      LINE='1'
    fi
  
    # Collect device size information

    if [ "$1" = "Size:" ] && [ "$CHKC" != "Sub" ]; then
      SIZE=`echo $4 $5 | sed s/[\(\)]//g`
    fi

    # Collect disk device, state, reloc, and spare data

    if [ "$CHKD" = "c" ]; then
      DISKDEV=`echo $1`
      MOUNTPT='-'
      USED='-'
      STATE=`echo $4`

      # Create 'tree' connections between devices and sub-devices

      CHKN=`echo "$DEVNAME" | awk '{print substr($1,1,1)}'`
      if [ "$CHKC" = "Sub" ] && [ "$CHKN" = "d" ]; then
        DEVNAME=`echo "|__"$DEVNAME`
      fi

    fi

    if [ "$2" = "Relocation" ]; then
      echo $DEVNAME $DISKDEV $MOUNTPT $SIZE $USED $STATE $COMMENT | \
        awk '{printf"%-11s %-11s %-12s %-3s %-3s %-5s %-11s %s %s %s\n\n",\
          $1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | sed s/-/' '/g
      break;
    fi
  done

}

################################################################################
# SysChk Main
#
# Called By  : n/a
# Calls      : log_chk(), link_chk(), meta_chk()
# Inputs     : n/a
# Returns    : Formatted information on system status to stdout
#
# Description: Calls a variety of shell commands and formats the output into
#              an organized report on current system status.
#
################################################################################

#!/bin/sh

# Set PATH for the program so we don't have to include complete paths to all
# shell commands

PATH=/usr/bin:/usr/sbin/:/etc;export PATH
ALL='Y'

while getopts dlins flag
do
  case $flag in
     d) DISK='Y'; ALL='';;
     l) LOG='Y'; ALL='';;
     i) HELP='Y'; ALL='';;
     n) NET='Y'; ALL='';;
     s) SYS='Y'; ALL='';;
    \?) echo "\nUsage: syschk [-d] [-l] [-i] [-n] [-s]"
        echo "\nSysChk generates as complete a picture of current system status"
        echo "as possible, including uptime, basic system config, cpu status,"
        echo "reboot history, current and past users, system and security logs,"
        echo "running processes, disk, array, and file system status, swap"
        echo "space status, network interface status, and current network"
        echo "connections. By default SysChk returns all information."
        echo
        echo "\n-d) Include disk/array/filesystem information"
        echo "-l) Include log file/security information"
        echo "-h) Show this message"
        echo "-i) Include explanation of output (verbose)"
        echo "-n) Include network information"
        echo "-s) Include system configuration information\n"
        exit;;
  esac
done

################################################################################
# The Hostname section lists the hostname of the system. It is generated by the 
# "hostname" command. Print the hostname for all options.

echo "Hostname"
echo "========"
hostname

# Check to see if the user has specified the -s option for system information
# If no options specified, show all information

if [ -n "$SYS" ] || [ -n "$ALL" ]; then

################################################################################
# The Uptime section describes the current time,  the  length  of time  the 
# system has been up since the last boot, and the average number of jobs in the 
# run queue over the last 1, 5 and 15 minutes. It is generated by the "update"
# command.

echo "\nUptime"
echo "======"

if [ -n "$HELP" ]; then
  echo ": Current time, plus the length of time the system has been up since the"
  echo ": last boot, and the average number of jobs in the run queue over the"
  echo ": last 1, 5 and 15 minutes\n"
fi

uptime

################################################################################
# The Configuration section describes the hardware model and type of the system,
# the memory size, and the operating system version (including the kernel 
# level). It is parsed from the output of the "uname" and "prtconf" commands.
# To see a list of all the patches installed on the system, run the 
# "showrev -p" command. To see a list of the installed application packages on
# the system, run the "pkginfo -c application -l" command.

echo "\nConfiguration"
echo "============="

if [ -n "$HELP" ]; then
  echo ": Hardware model, system configuration type, RAM memory size,"
  echo ": operating system version including kernel level, and open windows"
  echo ": version."
  echo ": To see a list of all the patches installed on the system, run"
  echo ": the 'showrev -p' command."
  echo ": To see list of installed application packages on the system, run"
  echo ": the 'pkginfo -c application -l' command."
fi

echo "\nHardware: " `uname -i`
prtconf | grep ":" | grep -v Software
echo "OS/Kernel Version: " `uname -srv`
showrev -w

################################################################################
# The CPU Status section describes the number, type, speed, and state of each 
# processor on the system. It is generated by the "psrinfo -v" command. If the 
# processor is described as sparcv9, the system is running in 64-bit mode 
# (default if CPU is faster than 200MHz). If the processor is described as 
# sparc, the system is running in 32-bit mode.

echo "CPU Status"
echo "=========="

if [ -n "$HELP" ]; then
  echo ": The number, type, speed, and state of each processor (CPU) on the"
  echo ": system. If the processor is described as sparcv9, the system is"
  echo ": running in 64-bit mode (default is CPU is faster than 200MHz). If"
  echo ": the processor is described as sparc, the system is running in"
  echo ": 32-bit mode."
fi

echo
psrinfo -v

fi

# Check to see if the user has specified the -l option for security information
# If no options specified, show all information

if [ -n "$LOG" ] || [ -n "$ALL" ]; then

################################################################################
# The Recent Reboots section lists the dates and times of the last five system
# reboots. It is generated by the "last -n 5 reboot" command.

echo "\nRecent Reboots"
echo "=============="

if [ -n "$HELP" ]; then
  echo ": Time and date of the last five system boots"
fi

echo
last -n 5 reboot

################################################################################
# The Current Users section describes users currently logged into the system, 
# how long they have been idle, how much processor time they have used and any 
# commands they are currently executing. It is generated by the "w" command.

echo "\nCurrent Users"
echo "============="

if [ -n "$HELP" ]; then
  echo ": Users currently logged on to the system, how long they have been"
  echo ": idle, how much processor time they have used and any commands"
  echo ": they are currently executing"
fi

echo
w

################################################################################
# The Recent Logins section lists the dates and times of last 10 user logins to 
# the system. It also describes where the user connected from and how long each 
# login session lasted. It is generated by the "last -n 10" command. 

echo "\nRecent Logins"
echo "============="

if [ -n "$HELP" ]; then
  echo ": The dates and times of the last 10 user logins to the system. Also"
  echo ": describes where the user connected from and how long each login"
  echo ": session lasted."
fi

echo
last -n 10

################################################################################
# The Number of Bad Logins section relates info from the EPROM on the number of
# bad logins to the boot prom (ok or > prompts). It is enabled by entering the
# 'eeprom security-#badlogins=0' and the 'eeprom security-mode=command'
# commands. After the second command you will be prompted for a password which
# will later be required for any commands issued at the boot prom other than
# standard multi-user boot commands.

echo "\nNumber of Bad Prom Logins"
echo "========================="

if [ -n "$HELP" ]; then
  echo ": Dislays the number of bad boot prom logins when 'command' security"
  echo ": mode is enabled for the prom. Value should always be 0."
fi

echo
echo "prom" `eeprom security-mode`
echo "prom" `eeprom security-#badlogins`

################################################################################
# The System Messages section dislays the last 20 lines of the /var/adm/messages
# file and/or the /var/adm/messages.0 file (whatever adds up to 20 lines). The
# top of the section will relate which files the messages came from. These files
# contain general system messages.

echo "\nSystem Messages (/var/adm/messages)"
echo "==================================="

if [ -n "$HELP" ]; then
  echo ": The last 20 lines of the /var/adm/messages file and/or the"
  echo ": /var/adm/messages.0 file (whatever adds up to 20 lines). These files"
  echo ": contain general system messages."
fi

echo
log_chk "/var/adm/messages"

################################################################################
# The Authorization Messages section displays the last 20 lines of the 
# /var/log/authlog file and/or the /var/log/authlog.0 file (whatever adds up to
# 20 lines). The top of the section will relate which files the messages came
# from. These files contain messages related to user authentication. If this
# log does not exist, it can be populated by adding the following entry to the
# /etc/syslog.conf file:
#
# auth.info                                       /var/log/authlog
#
# and the following line to the /etc/logadm.conf file:
#
# /var/log/authlog -C 8 -P 'Thu Aug 12 03:10:00 2004' -a 'kill -HUP `cat /var/run/syslog.pid`'

echo "\nAuthorization Messages (/var/log/authlog)"
echo "========================================="

if [ -n "$HELP" ]; then
  echo ": The last 20 lines of the /var/log/authlog file and/or the"
  echo ": /var/log/authlog.0 file (whatever adds up to 20 lines). These files"
  echo ": contain messages related to user authentication."
fi

echo
log_chk "/var/log/authlog"

################################################################################
# The Connection Messages section dislays the last 20 lines of the 
# /var/log/connlog file or the /var/log/connlog.0 file (whatever adds up to 20
# lines). The top of the section will relate which files the messages came from.
# These files contain messages related to network connections. If this log does
# not exist, it can be populated by adding the following entry to the
# /etc/syslog.conf file:
#
# daemon.debug                                    /var/log/connlog
#
# and the following line to the /etc/logadm.conf file:
#
# /var/log/connlog -C 8 -P 'Thu Aug 12 03:10:00 2004' -a 'kill -HUP `cat /var/run/syslog.pid`'

echo "\nConnection Messages (/var/log/connlog)"
echo "======================================"

if [ -n "$HELP" ]; then
  echo ": The last 20 lines of the /var/log/connlog file and/or the"
  echo ": /var/log/connlog.0 file (whatever adds up to 20 lines). These files"
  echo ": contain messages related to user authentication."
fi

echo
log_chk "/var/log/connlog"

################################################################################
# The Running processes section displays information on all processes currently
# running on the system, including uid of the process owner, processor time used
# by the process, and the command line of the process. Note: Look for user (not
# root owned) processes with high CPU times or that appear to be performing
# unusual functions. This section is generated by the "ps -ef" command.

echo "\nRunning Processes"
echo "================="

if [ -n "$HELP" ]; then
  echo ": Information about all the processes currently running on the system,"
  echo ": including uid of the process owner, processor time used by each"
  echo ": process, and the command line of each process. Look for user owned"
  echo ": processes with high CPU times or that appear to be performing"
  echo ": unusual functions."
fi

echo
ps -ef

fi

# Check to see if the user has specified the -d option for disk information
# If no options specified, show all information

if [ -n "$DISK" ] || [ -n "$ALL" ]; then

################################################################################
# The Disk / Array Status section contains summary information on the disk
# partitions and RAID-1 arrays on the system, including metadevice name, actual
# disk device name, mount point, size, percent used, current state, and a
# description of what the partition of metadevice is. It is generated by the
# metachk script. Look for States other than Okay or Used values higher than 
# 80%.

# Check to see if system has any metadevices configured. If metadevices are
# present, print summary info.

META=`df -k | grep "/dev/md" | wc -l`
if [ "$META" -ne "0" ]; then

  echo "\nDisk / Array Status"
  echo "==================="

  if [ -n "$HELP" ]; then
    echo ": Information about disk partitions and RAID-1 arrays, including"
    echo ": metadevice names, actual disk device names, mount points, size,"
    echo ": percent used, current state, and a short description of each"
    echo ": device. Look for states other than Okay or Used values higher"
    echo ": than 80%"
  fi

  # Open the report file and print the column headers

  echo "\nMeta Device State Check Summary"
  echo "\nMetaDevice  DiskDevice  Mount Point  Size    Used  State       Comment"
  echo "==========  ==========  ===========  ======  ====  ==========  ==============="

  # Run metastat and parse the output

  meta_chk 

  echo "Meta DB Status"
  echo "=============="

  if [ -n "$HELP" ]; then
    echo ": Information about metadevice state databases. See key below for"
    echo ": explanation of individual flags"
  fi

  echo
  /usr/sbin/metadb -i 
fi

################################################################################
# The File Systems section contains summary information on mounted file systems,
# including device names, mount points, size, percent used, etc. It is generated
# by the "df -k" command. Watch for low free space or for unusual network
# mounted file systems.

echo "\nFile Systems"
echo "============"

if [ -n "$HELP" ]; then
  echo ": Information on mounted file systems, including device names, mount"
  echo ": points, size, percent used, etc. Watch for low free space or for"
  echo ": unusual network mounted file systems."
fi

echo
df -k

################################################################################
# The Swap Space section describes the state of the system's swap space, 
# including physical location, size, and amount free space. It is generated by 
# the "swap -l" and "swap -s" commands. Watch for low free space.

echo "\nSwap Space"
echo "=========="

if [ -n "$HELP" ]; then
  echo ": State of the system's swap space, including physical location, size,"
  echo ": and amount of free space. Watch for low free space."
fi

echo
swap -l
echo 
swap -s

fi

# Check to see if the user has specified the -n option for network information
# If no options specified, show all information

if [ -n "$NET" ] || [ -n "$ALL" ]; then

################################################################################
# The Network Interfaces section describes the state of the system's network
# interface cards, including IP addresses, network settings, MAC addresses, and
# current connection speed and mode. It is generated by the "ifconfig -a" and 
# "ndd -get /dev/eri [parameter]" commands. Note: Speed and Mode should always 
# be 100 Mbit, Full Duplex, with Auto Negotiate On.

# Print output of ifcongig -a

echo "\nNetwork  Interfaces"
echo "==================="

if [ -n "$HELP" ]; then
  echo ": The state of the system's network interfaces, including IP address,"
  echo ": network settings, MAC addresses, and current connection speed and"
  echo ": mode."
fi

echo
ifconfig -a
echo

# For each interface other than the loopback, evaluate the interface speed,
# mode, and autonegotiate settings.

eval "ifconfig -a" | while read line
do
  DEVNM=`echo $line | grep -v "lo0" | grep "0: " | awk '{print $1}' | sed s/0://g`
  LINKNM=`echo $line | grep ":" | awk '{print $1}' | sed s/://g`
  if [  -n "$DEVNM" ]; then
    link_chk $DEVNM $LINKNM
    echo
  fi
done

################################################################################
# The Routing Tables section displays the system's current routing table 
# information. It is generated by the "netstat -r" command. Watch for new or odd 
# routes that point to unknown IP addresses.

echo "Routing Tables"
echo "=============="

if [ -n "$HELP" ]; then
  echo ": The system's current routing table information. Watch for new or odd"
  echo ": routes that point to unknown IP addresses."
fi

echo
netstat -r

################################################################################
# The Network Connections section describes all current network connections to 
# or from the system. It is generated by the "netstat -a" command. Look for any
# connections to unknown IP addresses or using unusual port numbers. Note that
# IPv6 data will be displayed even though IPv6 is not enabled on the system.

echo "\nNetwork Connections"
echo "==================="

if [ -n "$HELP" ]; then
  echo ": Current network connections to or from the system. Look for any"
  echo ": connections to unknown IP addresses or using unusual port numbers."
  echo ": Note that IPv6 data may be displayed even though IPv6 is not"
  echo ": enabled on the system."
fi

echo
netstat -a
echo

fi

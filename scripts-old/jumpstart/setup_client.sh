#!/bin/bash
# usage: :
# Check for inet boot file in /tftpboot of correct version.
if [ -f "/tftpboot/inetboot.sol$4.sun4u" ]
then
  echo "Inet boot file for Solaris $4 found, continuing ..."
else
  echo "Could not find a suitable boot file in /tftpboot, exiting ..."
fi

# Convert ip address to hex for boot file.
# First we exchange commas for the dots in the address string.
IP=`echo $3|awk -F. '{print $1","$2","$3","$4}'`
echo "Old notation $3 converted to $IP, continuing ..."
HEX=`perl -e 'printf "%02x"x4 . "\n",'$IP';' | tr a-z A-Z`
cp /tftpboot/inetboot.sol$4.sun4u /tftpboot/$HEX
cp /tftpboot/inetboot.sol$4.sun4u /tftpboot/$HEX.sun4u

# Start rarp and bootparams daemons on the specified
# interface.
# Get current ip address.
IPSVR=`ifconfig $5|grep -v inet6|grep inet|awk '{print $2}'`
echo "Killing old processes if active, ..."
killall rarpd
killall bootparamd
echo "Server ip address is $IPSVR, starting daemons, ..."
/usr/sbin/rarpd -d $5&
/usr/sbin/bootparamd -d -r $IPSVR&
echo "Starting ping for client for icmp request replies ..."
/sbin/ping $1 >>/dev/null 2>&1
echo "Done."
exit 0

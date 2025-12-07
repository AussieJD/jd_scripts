#!/bin/sh
# Script Name : MetaSetRemove.sh
# Version     : 2.0
# Description : This script will revert a metaset build for a Solaris zone 
# Usage       : 
# Dependencies: None
# Keynote     : 
#             : 
#*------------------------------------------------------------
# Changes    :
# Date of change    Author of change       Change details
# 28/04/2010 : qz4bfb          Initial release
# 28/10/2006 : qz4bfb          Fix code to use one entry for zone/metaset name and work out rest.
# 15/12/2011 : qz4bfb          Fix code to use zone name for arg and shutdown and delete zone from global
#            :                 Will delete zone now. More warnings and error handling.
#            :
# *-----------------------------------------------------------------------------------------------
# Variable defs
#*------------------------------

Global1=adl1111
Global2=adl1112

#*------------------------------------------------------------
# Subroutines
#*------------------------------------------------------------

DateStamp () { echo "`date +\"%Y%m%d\"`" ; }

PrintUsage() {

cat <<-ENDOFMESSAGE

WARNING:

   This script requires a host name argument!  
      e.g. /opt/EDS/sbin/MetaSetRemove.sh adl1229
 
ENDOFMESSAGE

} # End PrintUsage

PrintWarn () {
   cat <<-ENDOFMESSAGE
*------------------------------------------------------------------------------------*
*  This script will delete a metaset and zone from the current physical server.      *
*            The Metaset will be deleted on both hosts it is defined on.             *
*                     This process is not reversible                                 *
*                         Is this your intention?                                    *                      
*                                                                                    *
*       Prechecks: ensure no one is using the zone and no fs's in the zone  are      *
*                                    broken                                          *                                                                                    *
*------------------------------------------------------------------------------------*
ENDOFMESSAGE

} # End PrintWarn

ShutDownZone () {
    zlogin $ZoneHost halt 
    while [ ! "$Result" ] ; do
       # Now we wait for it to stop
       Result="`zoneadm list -cv | grep $ZoneHost | grep installed`"
       sleep 5
    done
}  # End ShutDownZone

# *---------------------------------------------------------------------
# Main
# *---------------------------------------------------------------------
Suffix=`DateStamp`

if [ $# -lt 1 ] ; then PrintUsage ; exit 2 ; fi

ZoneHost=$1        # Zone and metaset to remove

# Split off four digits to get number "string" (always assumes name form is adlNNNN)
HostNo="`echo $ZoneHost | sed 's/^...//'`" 
MetSet=${HostNo}zone

PrintWarn
echo "You have selected ${ZoneHost} for deletion!  Please confirm delete of zone and metaset. (y/n)"
read Ans
[ "$Ans" = "Y" -o "$Ans" = "y" ] && {  echo "Starting zone and metaset deletion!" ; } ||  { echo " Abort run" ; exit 1 ; }

# Manage zone deletion
# Check that zone is not running. If so, shut it down and wait until down
zoneadm list -vc | grep $ZoneHost |grep running
[ $? -eq 0 ] && { echo "$ZoneHost is running! Shutting it down" ; ShutDownZone ; }

# Now uninstall the zone
echo " Hit return to continue! Ctrl C to abort"  ; read GoOn

echo "zoneadm -z $ZoneHost uninstall"
zoneadm -z $ZoneHost uninstall

echo "zonecfg -z $ZoneHost delete"
zonecfg -z $ZoneHost delete

echo "Unmount filesystems for ${ZoneHost}"
# Produces list of mount points related to zone metaset  and unmount them.
for mount in `df -k | grep ${MetSet} |grep 'fs' | awk '{ print $6 }'`
do
   echo  "umount $mount!"
   umount $mount
done

# Now unmount /zones/host filesystem
ZoneRoot="`df -k | grep ${MetSet} | grep -v 'fs' | awk '{print $6}'`"
echo "Unmounting $ZoneRoot"
umount $ZoneRoot
[ $? -ne 0 ] && { echo "Failed to unmount $ZoneRoot" ; exit 1 ; }

# Metaclear Soft Partitions
for part in `metastat -s ${MetSet} -p | grep 'rdsk' | awk '{ print $1 }'`
do
   part=`echo $part | awk -F/ '{ print $2 }'`
   echo "metaclear -s ${MetSet} $part"
   metaclear -s ${MetSet} $part
done

# Metaclear Metadevice on Metaset
part=`metastat -s ${MetSet} -p | grep -v 'rdsk' | awk '{ print $1 }'`
part=`echo $part | awk -F/ '{ print $2 }'`
Lun=`metastat -s ${MetSet} -p | grep -v rdsk | awk '{ print $4 }' | sed 's/s0//'"`

echo "metaclear -s ${MetSet} $part"
metaclear -s ${MetSet} $part
echo "metaset -s ${MetSet} -f -d $Lun"
metaset -s ${MetSet} -f -d $Lun
echo "metaset -s ${MetSet} -d -h $Global1"
metaset -s ${MetSet} -d -h $Global1
echo "metaset -s ${MetSet} -d -h $Global2"
metaset -s ${MetSet} -d -h $Global2

echo "cp -p /etc/vfstab /etc/vfstab.$Suffix.$$"
cp -p /etc/vfstab /etc/vfstab.$Suffix.$$
echo "cp -p /etc/lvm/md.tab /etc/lvm/md.tab.$Suffix.$$"
cp -p /etc/lvm/md.tab /etc/lvm/md.tab.$Suffix.$$

cat /etc/vfstab | grep -v ${MetSet} | grep -v $ZoneHost > /tmp/vfstab.$$
cat /tmp/vfstab.$$ > /etc/vfstab

cat /etc/lvm/md.tab | grep -v ${MetSet} > /tmp/mdtab.$$
cat /tmp/mdtab.$$ > /etc/lvm/md.tab

echo "Remove ${ZoneHost}.cfg"
[ -f "$CFGfile" ] && { rm $CFGfile ; }

exit 0
 
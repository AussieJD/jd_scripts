#!/bin/sh
# Script Name : ReleaseZone.sh
# Version     : 1.1
# Description : This script will release a zone and it's metaset from the local host.
#             :
# Assumptions : This host is configured on the san to be able to access the lun (metaset)
#             : 
# Usage       : 
#             :
# Dependencies: /var/zones exists on remote and is 770
# Keynote     : Metaset can only be active on one host at a time.  
#             : 
#*------------------------------------------------------------                                            
# Changes    :
# Date of change    Author of change       Change details
# 5/05/2010 : qz4bfb          Initial release
# 24/10/2006 : qz4bfb          Fix xxxx#             :
#             :
#             :
# *-----------------------------------------------------------------------------------------------
# Variable defs
#*------------------------------
# Ensure common tools are found in path for this session

SCRIPTDIR=/opt/EDS/sbin
Vfstab=/etc/vfstab
      
METASTAT=/usr/sbin/metastat
MOUNT=/usr/sbin/mount
UMOUNT=/usr/sbin/umount
METASET=/usr/sbin/metaset

Global1=adl1111
Global2=adl1112

#*------------------------------------------------------------
# Subroutines
#*------------------------------------------------------------      

PrintUsage() {

cat <<-ENDOFMESSAGE

WARNING:

      This script requires a host name argument!  
    
      e.g. /opt/EDS/bin/ReleaseZone.sh adl0510

EVENT SEQUENCE:

1. Export detached.xml file from zone
2. Shutdown zone with i5 switch
3. scp detached.xml file to new host
4. Detach zone from local global
5. Unmount filesystems from local global
6. Release metaset from local global.     
 
ENDOFMESSAGE

} # End PrintUsage

PrintWarn () {
   cat <<-ENDOFMESSAGE
*------------------------------------------------------------------------------------*
*  This script will release a metaset and it's zone from the current physical server.*
*            Metaset can only be active on one host at a time.                       * 
*                                                                                    *
*   This will dettach host $Host on global $Global, and release it's metaset!      *
*                     Is this you intention? ( y/n )                                 *                      
*                                                                                    *
*------------------------------------------------------------------------------------*
ENDOFMESSAGE

} # End PrintWarn

ShutDownZone () {
    zlogin $ZONENAME init 5 
    while [ ! "$Result" ] ; do
       # Now we wait for it to stop
       Result="`zoneadm list -cv | grep $ZONENAME | grep installed`"
       sleep 10
    done
}  # End ShutDownZone

# *---------------------------------------------------------------------
# Main
# *--------------------------------------------------------------------- 
Global="`uname -n`"
DATEBIT="`date +%\Y%\m%\d-%\H%\M%\S`"

if [ $# -lt 1 ] ; then PrintUsage ; exit 2 ; fi

# Argument is the hostname
Host="$1"
echo " Processing for zone $Host"
PrintWarn 
read Ans
[ "$Ans" = "Y" -o "$Ans" = "y" ] && {  echo "Starting metaset release!" ; } ||  { echo " Abort run" ; exit 1 ; }

# Split off four digits to get number "string"
HOSTNUMBER="`echo $Host | sed 's/^...//'`" 
ZONEMETASET=${HOSTNUMBER}zone
ZONENAME=$Host

# Manage zone detach
# Check that zone is not running. If so, shut it down and wait until down
zoneadm list -vc | grep $ZONENAME |grep running
[ $? -eq 0 ] && { echo "$ZONENAME is running! Shutting it down" ; ShutDownZone ; }

# Now generate manifest file for attach on remote host
DetachFile="${ZONENAME}.detach.${DATEBIT}.xml"
zoneadm -z $ZONENAME detach  -n > /zones/$DetachFile
chmod 660 /zones/$DetachFile

# Unmount filesystems - remove zone mount fs last
for fs in `df -k | grep ${ZONEMETASET} | grep 'fs' | awk '{print $6}'`
do
    echo "Unmounting $fs"
    $UMOUNT $fs
    Result="$?"
    while [ "$Result" -ne 0 ] ; do 
       echo "Failed to unmount $fs! Will sleep for 30 seconds and retry"
       sleep 30
       $UMOUNT $fs ; Result="$?" 
    done
done

# While /zones/$ZONENAME is still mounted detach zone
echo "Detaching $ZONENAME zone"
zoneadm -z $ZONENAME detach
[ $? -ne 0 ] && { echo "Error Detaching $ZONENAME" ; exit 1 ; }

# Take backup copies of detached xml to both servers.  Needs ssh keys set up for security
# Work out who this global is and set remote global for copy.
[ "$Global" = "$Global1" ] && { Remote="$Global2" ; } ||  { Remote="$Global1" ; }

# echo "Copying $DetachFile to $Remote:/zones/$DetachFile"
# su security -c "scp /zones/$DetachFile $Remote:/var/zones/$DetachFile"

# Now unmount /zones/host filesystem
ZoneRoot="`df -k | grep ${ZONEMETASET} | grep -v 'fs' | awk '{print $6}'`"
echo "Unmounting $ZoneRoot"
$UMOUNT $ZoneRoot
[ $? -ne 0 ] && { echo "Failed to unmount $ZoneRoot" ; exit 1 ; }

echo "Copying $MetaP to $Remote:/zones/$MetaP"
MetaP="metastatp.$ZONEMETASET.$DATEBIT"
echo "$METASTAT -s $ZONEMETASET -p > /var/zones/$MetaP"
$METASTAT -s $ZONEMETASET -p > /var/zones/$MetaP
chmod 660 /var/zones/$MetaP
# su security -c "scp /var/zones/$MetaP $Remote:/var/zones/$MetaP"

echo "Releasing metaset $ZONEMETASET from $Global"
$METASET -s $ZONEMETASET -r
[ $? -ne 0 ] && { echo "Error releasing $ZONEMETASET"  ; exit 1  ; }

# echo "/zones/$DetachFile is available on $Remote if required for attach tests."
echo "Zone ${Host} release is complete"

exit 0

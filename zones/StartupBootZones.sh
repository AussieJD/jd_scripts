#!/bin/ksh
# Script Name : StartupBootZones.ksh
# Version     : 1.0
# Description : Designed to autostart/stop zones,
#             : that are supposed to be on this global, after a global restart.
#             :
# Assumptions : All zones in list should be running on this global
#             : This host is configured on the san to be able to access the lun (metaset)
#             : Ensure correct entries already exist in vfstab for filesystem mounts.(set to no mount at boot)
#             : Mount order in vfstab is critical or susequent mounts will fail.
# Usage       : /opt/EDS/sbin/StartupBootZones.sh # Invoked at startup
#             :
# Dependencies: Correct entries in vfstab for fs mounts.  This host knows about metaset.
# Keynote     : Metaset can only be active on one host at a time.  
#*------------------------------------------------------------                                            
# Changes    :
# Date of change    Author of change       Change details
# 3/08/2011 : qz4bfb          Initial release
# 24/10/2011 : qz4bfb          Fix xxxx#             :
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

Global1=adl1250
Global2=adl1251

ZoneList="adl1252 adl1254 adl1256 adl1257"

#*------------------------------------------------------------
# Subroutines
#*------------------------------------------------------------

#-----------------------------------------------------------------
# ShutDownZone:
# Will take the zone down and wait until it's down.
#-----------------------------------------------------------------
ShutDownZone () {
    zlogin $ZONENAME init 5 
    while [ ! "$Result" ] ; do
       # Now we wait for it to stop
       Result="`zoneadm list -cv | grep $ZONENAME | grep installed`"
       sleep 10
    done
}  # End ShutDownZone

#-----------------------------------------------------------------
# ReleaseZone:
# Will take the zone down, unmount filesystems, detach zone and
# release metaset from server.
#-----------------------------------------------------------------
ReleaseZone () {
      # Argument is the hostname
      Host="$1"
      echo " Processing for zone $Host"
      HOSTNUMBER="`echo $Host | sed 's/^...//'`" 
      ZONEMETASET=${HOSTNUMBER}zone
      ZONENAME=$Host
   
      # Manage zone detach. Check that zone is not running. If so, shut it down and wait until down
      zoneadm list -vc | grep $ZONENAME |grep running
      [ $? -eq 0 ] && { echo "$ZONENAME is running! Shutting it down" ; ShutDownZone ; }

      # While /zones/$ZONENAME is still mounted detach zone
      echo "Detaching $ZONENAME zone"
      zoneadm -z $ZONENAME detach
      [ $? -ne 0 ] && { echo "Error Detaching $ZONENAME" ; exit 1 ; }      

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

      # Now unmount /zones/host filesystem
      ZoneRoot="`df -k | grep ${ZONEMETASET} | grep -v 'fs' | awk '{print $6}'`"
      echo "Unmounting $ZoneRoot"
      $UMOUNT $ZoneRoot
      [ $? -ne 0 ] && { echo "Failed to unmount $ZoneRoot" ; continue ; }
      
      echo "Releasing metaset $ZONEMETASET from $Global"
      $METASET -s $ZONEMETASET -r
      [ $? -ne 0 ] && { echo "Error releasing $ZONEMETASET"  ; continue ; }
      
      echo "Zone ${Host} release is complete"
            
} # End ReleaseZone

#-----------------------------------------------------------------
# LoadZone:
# Will take the metaset, mount filesystems and attach and boot zone
# passed as an argument to the sub
#-----------------------------------------------------------------
LoadZone () {
    # Argument is the hostname
    ZONENAME="$1"
    echo " Processing for zone $ZONENAME"
    
    # Split off four digits to get number "string"
    HOSTNUMBER="`echo $ZONENAME | sed 's/^...//'`" 
    ZONEMETASET=${HOSTNUMBER}zone
        
    # Test if already owned by this global or remote global.  Skip or exit if so.
    echo "Testing ownership of metaset $ZONEMETASET"
    [ "$Global" = "$Global1" ] && { Remote="$Global2" ; } ||  { Remote="$Global1" ; }
    # Test remote host
    Owner=`su security -c "ssh $Remote /usr/sbin/metaset -s $ZONEMETASET | grep $Remote | grep Yes"`
    [ ! "$Owner" = "" ] && { echo "Metaset $ZONEMETASET is owned by $Remote!  Exiting!" ; continue ; }
    # Test local host, take if not owner.
    Owner=`/usr/sbin/metaset -s $ZONEMETASET | grep $Global | grep Yes`
    if [ ! "$Owner" = "" ] ; then
       echo "Warning: Metaset $ZONEMETASET is already owned by $Global!"    
    else
       echo "Taking metaset $ZONEMETASET onto $Global"
       $METASET -s $ZONEMETASET -t
       [ $? -ne 0 ] && { echo "Error taking $ZONEMETASET"  ; continue ;}
    fi   
        
    # Now mount zones/host filesystems, root first. (Exclude if it has "/fs" in it, e.g /zones/adl1226/fs/??)
    ZoneRoot="`cat $Vfstab | grep ufs | grep -v '^#' | grep $HOSTNUMBER | grep -v '\/fs' | awk '{print $3}'`"
    echo "Mounting $ZoneRoot"
    sleep 5
    $MOUNT $ZoneRoot
    [ $? -ne 0 ] && { echo "Failed to mount $ZoneRoot" ; continue ;}
    
    # Mount filesystems
    for fs in `cat $Vfstab | grep ufs | grep -v '^#' | grep $HOSTNUMBER | grep '\/fs' | awk '{print $3}'`
    do
        echo "Mounting $fs"
        sleep 2
        $MOUNT $fs
        [ $? -ne 0 ] && { echo "Failed to mount $fs" ; continue ;}
    done
    
    [ "`/usr/sbin/ping $HostIP | awk '{ print $3 }'`" == "alive" ] && { echo "Host already using this ip address! Exiting" ; continue ; }
    
    # Check status of Zone
    ZoneState="`zoneadm list -vc | grep $ZONENAME | awk '{ print $3 }'`"
    case $ZoneState in
        "configured")   echo "Attaching $ZONENAME zone"
                        if [ "`zoneadm list -cv | grep $ZONENAME | awk '{ print $5 }'`" = "solaris8" ] ; then
                           zoneadm -z $ZONENAME attach  -F
                           [ $? -ne 0 ] && { echo "Failed to attach $ZONENAME zone" ; continue ; }
                           /usr/lib/brand/solaris8/s8_p2v $ZONENAME
                        else
                           zoneadm -z $ZONENAME attach
                           [ $? -ne 0 ] && { echo "Failed to attach $ZONENAME zone" ; continue ; }    
                        fi
                        echo "Booting Zone $ZONENAME"
                        zoneadm -z $ZONENAME boot
                        zoneadm list -vc
                        ;;
        "installed" )   echo "$ZONENAME is already in an INSTALLED state. Booting it up"
                        echo "Booting Zone $ZONENAME"
                        zoneadm -z $ZONENAME boot
                        zoneadm list -vc
                        ;;
    esac
                                     

} # End LoadZone     

# *---------------------------------------------------------------------
# Main
# *---------------------------------------------------------------------
Global="`uname -n`"

case "$1" in
'start')
        # Process the list of zones to start on this global
        for ZoneName in `echo $ZoneList`  ; do
           echo "Processing $ZoneName"
           LoadZone $ZoneName
        done
        ;;
'stop')
        # Process the list of zones to stop on this global
        for ZoneName in `echo $ZoneList`  ; do
           echo "Processing $ZoneName"
           ReleaseZone $ZoneName
        done 
        ;;
*)
        echo "Usage: $0 { start | stop }"
        exit 1
        ;;
esac

exit 0

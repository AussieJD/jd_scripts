#!/bin/ksh
# Script Name : LoadZone.ksh
# Version     : 1.1
# Description : This script will take a metaset containing a Solaris zone onto 
#             : the local host if it is a metaset host.
#             :
# Assumptions : This host is configured on the san to be able to access the lun (metaset)
#             : Ensure correct entries already exist in vfstab for filesystem mounts.(set to no mount at boot)
#             : Mount order in vfstab is critical or susequent mounts will fail.
# Usage       : /opt/EDS/sbin/LoadZone.sh {hostname}
#             :
# Dependencies: Correct entries in vfstab for fs mounts.  This host knows about metaset.
# Keynote     : Metaset can only be active on one host at a time.  
#*------------------------------------------------------------                                            
# Changes    :
# Date of change    Author of change       Change details
# 5/05/2010 : qz4bfb          Initial release
# 5/07/2011 : qz4bfb          Fix code for mout root of zone.
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
METASET=/usr/sbin/metaset

Global1=adl1111
Global2=adl1112

#*------------------------------------------------------------
# Subroutines
#*------------------------------------------------------------

PrintUsage() {

cat <<-ENDOFMESSAGE

WARNING:

   This script requires at least a host name argument!  The optional switch 
   is -f which will force the taking of the zone's metaset onto the current
   global zone and starts the zone. Please don't use the -f switch unless necessary.
    
      e.g. /opt/EDS/bin/LoadZoneNice.sh -f adl0510
 
ENDOFMESSAGE

} # End PrintUsage

PrintWarn () {
   cat <<-ENDOFMESSAGE
*------------------------------------------------------------------------------------*
*  This script will import a metaset and zone to the current physical server.        *
*            Metaset can only be active on one host at a time.                       *
*            This will mount host $Host on global $Global!                        *
*                     Is this you intention? ( y/n )                                 *                      
*                                                                                    *
*------------------------------------------------------------------------------------*
ENDOFMESSAGE

} # End PrintWarn

# *---------------------------------------------------------------------
# Main
# *---------------------------------------------------------------------
Global="`uname -n`"

# * get option arguments if any*
FORCE=
while getopts fh: opt ; do
        case ${opt} in
                f) FORCE=F          ;;
                h) PrintUsage        ; exit 0 ;;
                ?) PrintUsage        ; exit 2 ;;
        esac
done

# validate that there are at least line arguments, loginname and fullname
shift $(($OPTIND - 1))
if [ $# -lt 1 ] ; then PrintUsage ; exit 2 ; fi
                                                      
# Argument is the hostname
ZONENAME="$1"
echo " Processing for zone $ZONENAME"

PrintWarn 
read Ans
[ "$Ans" = "Y" -o "$Ans" = "y" ] && {  echo "Starting metaset take!" ; } ||  { echo " Abort run" ; exit 1 ; }

# Split off four digits to get number "string"
HOSTNUMBER="`echo $ZONENAME | sed 's/^...//'`" 
ZONEMETASET=${HOSTNUMBER}zone

if [ "$FORCE" ]  ; then
   echo "Taking metaset $ZONEMETASET onto $Global by force"
   $METASET -s $ZONEMETASET -t -f
   [ $? -ne 0 ] && { echo "Error taking $i"  ; exit 1  ;}
else
   # Test if already owned by this global or remote global.  Skip or exit if so.
   echo "Testing ownership of metaset $ZONEMETASET"
   [ "$Global" = "$Global1" ] && { Remote="$Global2" ; } ||  { Remote="$Global1" ; }
   # test remote host
   Owner=`su security -c "ssh $Remote /usr/sbin/metaset -s $ZONEMETASET | grep $Remote | grep Yes"`
   [ ! "$Owner" = "" ] && { echo "Metaset $ZONEMETASET is owned by $Remote!  Exiting!" ; exit 1 ; }
   # test local host, take if not owner.
   Owner=`/usr/sbin/metaset -s $ZONEMETASET | grep $Global | grep Yes`
   if [ ! "$Owner" = "" ] ; then
      echo "Warning: Metaset $ZONEMETASET is already owned by $Global!"    
   else
      echo "Taking metaset $ZONEMETASET onto $Global"
      $METASET -s $ZONEMETASET -t
      [ $? -ne 0 ] && { echo "Error taking $ZONEMETASET"  ; exit 1  ;}
   fi   
fi

# Now mount zones/host filesystems, root first. (Exclude if it has "fs" in it, e.g /zones/adl1226/fs/??)
ZoneRoot="`cat $Vfstab | grep ufs | grep -v '^#' | grep $HOSTNUMBER | grep -v '\/fs' | awk '{print $3}'`"
echo "Mounting $ZoneRoot"
sleep 5
$MOUNT $ZoneRoot
[ $? -ne 0 ] && { echo "Failed to mount $ZoneRoot" ; exit 1 ;}

# Mount filesystems
for fs in `cat $Vfstab | grep ufs | grep -v '^#' | grep $HOSTNUMBER | grep '\/fs' | awk '{print $3}'`
do
    echo "Mounting $fs"
    sleep 2
    $MOUNT $fs
    [ $? -ne 0 ] && { echo "Failed to mount $fs" ; exit 1 ;}
done

# End of metaset and filesystems, start with zone attach.

# Maybe search for ip of host and then ping it.  If ans then alert & exit, else
HostIP="`grep $ZONENAME /etc/hosts | awk '{ print $1 }'`"
if [ ! "$HostIP" ] ; then
   echo "Unable to find the hosts ip to test if running.  Please enter ip!" 
   read HostIP
   echo "$HostIP $ZONENAME >> /etc/hosts"
fi
   
[ "`/usr/sbin/ping $HostIP | awk '{ print $3 }'`" == "alive" ] && { echo "Host already using this ip address! Exiting" ; exit 1 ; }

# NOTE: Branded zones have issues if attached to patched globals.
# -Check if branded zone.  Then may need -F on attach. Then run /usr/lib/brand/solaris8/s8_p2v <zone> before boot command
# Check status of Zone
ZoneState="`zoneadm list -vc | grep $ZONENAME | awk '{ print $3 }'`"
case $ZoneState in
    "configured")   echo "Attaching $ZONENAME zone"
                    if [ "`zoneadm list -cv | grep $ZONENAME | awk '{ print $5 }'`" = "solaris8" ] ; then
                       zoneadm -z $ZONENAME attach  -F
                       [ $? -ne 0 ] && { echo "Failed to attach $ZONENAME zone" ; exit 1 ; }
                       /usr/lib/brand/solaris8/s8_p2v $ZONENAME
                    else
                       zoneadm -z $ZONENAME attach
                       [ $? -ne 0 ] && { echo "Failed to attach $ZONENAME zone" ; exit 1 ; }    
                    fi
                    echo "Booting Zone $ZONENAME"
                    zoneadm -z $ZONENAME boot
                    zoneadm list -vc
                    ;;
    "installed" )   echo "$ZONENAME is already in an INSTALLED state do you want just to boot it?"
                    echo "If this is simply after a reboot YES is the recommended option"
                    echo "Please enter Y or N"
                    read RESPONSE
                    if [ "$RESPONSE" = "Y" -o "$RESPONSE" = "y" ] 
                    then    
                       echo "Booting Zone $ZONENAME"
                       zoneadm -z $ZONENAME boot
                       zoneadm list -vc
                       exit 0
                    else
                       echo "Exiting please fix manually" ; exit 1
                    fi
                    ;;
esac
                                 
exit 0
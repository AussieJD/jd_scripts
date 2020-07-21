#!/bin/sh
# Script Name : ZoneMetasetBuild.sh
# Version     : 2.1
# Description : This script will build a metaset for creating a branded Solaris 8 zone and then restore 
#             : a running server to the zone to move it off old hardware.
#             :
# Assumptions : Server is connected to san and required lun is connected.  Flar is ready for build
#             : of zone. Zone config is correct for required build
# Usage       : Extensive mods required for each host to be created.  Includes:
#             : - lun id, metaset name, metadevice and softpartition names, mount points, fs sizes
#             : - Host for sharing metasets, i.e. primary and secondary hosts.
#             :
# Dependencies: Valid zone config file.  Suitable size lun.  Flar file to restore, <hostname>-system.flar.
#             : Updated ZoneBuild.fs and ZoneBuild.params files in /opt/EDS/etc
# Keynote     : Flar would probably be stored on an nfs mount still attached to the server
#             : that was its source. 
#             : Do not mount metaset soft parts as they can only be mounted on one host at a time.
#             : 
#*------------------------------------------------------------
# Changes    :
# Date of change    Author of change       Change details
# 23/04/2010 : qz4bfb          Initial release
# 24/10/2010 : qz4bfb          Fix xxxx#             
# 18/10/2010 : qz4bfb          Added code for non metaset for stand alone server.
# 09/08/2011 : qz4bfb          Added code for process ip address list
#             :
#             :
# *-----------------------------------------------------------------------------------------------
# Variable defs
#*------------------------------
# Ensure common tools are found in path for this session

SCRIPTDIR=/opt/EDS/sbin
ETCDIR=/opt/EDS/etc
PARAMSFILE=${ETCDIR}/ZoneBuild.params
INCLIST=${ETCDIR}/ZoneBuild.fs
Vfstab=/etc/vfstab
      
METASET=/usr/sbin/metaset
METAINIT=/usr/sbin/metainit
METATTACH=/usr/sbin/metattach
METASTAT=/usr/sbin/metastat
NEWFS=/usr/sbin/newfs

MKDIR=/usr/bin/mkdir
CHMOD=/usr/bin/chmod
MOUNT=/usr/sbin/mount

#*------------------------------------------------------------
# Subroutines
#*----------------

DateStamp () { echo "`date +\"%Y%m%d\"`" ; }

PressEnter () { echo "" ; echo "Press Enter to continue" ; read Ans ; }

#-----------------------------------------------------------------
# PrintSelect:
# Invoke to display simple menu selections 
#-----------------------------------------------------------------
PrintSelect () {
clear
cat <<-ENDOFMESSAGE

Please note: A native zone is a Solaris 10 zone and a Branded zone is either Solaris 8 or 9

         *----------------------*
         *-   Functions Menu   -*
         *----------------------*
     1 - Display Stages of Build Process
     
     2 - Create Metaset and mount filesystems for $MetaSet
     
     3 - Create Meta Device and mount filesystems for zone (stand alone server)
     
     4 - Build Branded Zone $HostInstall from flar image
     
     5 - Build Native  Zone $HostInstall from flar image
     
     6 - Clone an existing zone to a metaset or metadev

     0 - Exit and end script
     *----------------------------------------*
     
     Please Enter selection: 
ENDOFMESSAGE

} # End PrintSelect

#-----------------------------------------------------------------
# PrintStages :
# Invoke to display details of menu selection options 
#-----------------------------------------------------------------
PrintStages () {
clear
cat <<-ENDOFMESSAGE

    Sequence of events:
    
    Option I : Display Menu Functions, advise of info and actions needed

      Manual:
      This stage is about data collection, planning and setting up files.
      Calculate sizes for lun that is large as current total allocated 
      Lun = server fs sizes total + 10%  . Determine fs sizes as per existing fs sizes. 
      Note: Separate home from root so abe will work correctly
      Update params files ZoneBuild.params and ZoneBuild.fs in /opt/EDS/etc
      Prep for flar dump of server if build from flar.  
      NFS mount filesystem from target server to running server for flar build
      
    Option II : Prep metaset for installing zone
        
      Script will:
        Convert Lun to metaset
        Create metadevice on metaset
        Build Soft Partitions on lun for filesystems inc abe partition.  (Merge / & var)
        Newfs metadevs
        Update vfstab and md.tab
        Mount fs's ready for either Solaris 8 Branded zone or Solaris 10 cloned zone

    Option III : Prep meta device for installing zone
        
      Script will:
        Convert disk slices to meta device
        Build Soft Partitions on metadevice for filesystems inc abe partition.  (Merge / & var)
        Newfs metadevs
        Update vfstab and md.tab
        Mount fs's ready for either Solaris 8 Branded zone or Solaris 10 cloned zone
              
    Option IV : Build Branded zone from flar of physical server
      
      Script will:  
        Create zone config file and backup conf (including fs defs)
        Install zone with flar image 
        Boot zone
        
    Option V  : Build native Solaris 10 zone from flar of physical or virtual server
      
      Script will:  
        Create zone config file and backup conf (including fs defs)
        Install zone with flar image 
        Boot zone
                
    Option VI : Clone a zone from a template zone

      Script will:  
        Create zone config file and backup conf (including fs defs)
        Install zone clone existing zone
        Boot zone  for final configs  
          
    end
ENDOFMESSAGE

} # End PrintStages 

#-----------------------------------------------------------------
# PrintLast :
# Final notes regarding work to complete for zones on host pairs
#-----------------------------------------------------------------
PrintLast () {
cat <<-ENDOFMESSAGE

    *=============================================================================================*
    Please Note:
    
    Ensure you copy the entries, relevant to this zone, from the global /etc/vfstab and /etc/lvm/md.tab on 
    the host you built the zone on and  add them to the partner host global vfstab and md.tab.
    
    Also :
    
    Copy the <zonename>.cfg file to the partner host and configure (zonecfg) the zone so both nodes know about this zone.
    
    *=============================================================================================*   

ENDOFMESSAGE
} # End PrintLast

#-----------------------------------------------------------------
# PrintTarClone :
# Notes regarding keypoints and actions to take to tar clone a zone
#-----------------------------------------------------------------
PrintTarClone () {
cat <<-ENDOFMESSAGE

 *=============================================================================================*
 Cloning a zone via a tar copy.
    Ensure the target zone is built with the same filesystems structure as the source.
    Ensure the zonecfg file is ready to load to create the zone definition.
    Shut down the source zone
    
    Run "zoneadm -z <zone> detach -n > /tmp/SUNWdetached.xml" command to create file for attaching
    the newzone.
    Run "cd to /zone/<source zone>/"
    Run "tar cf - ./root ./fs ./dev | (cd /zones/<new zone> ; tar xvpf - )"
    Restart the source zone
    
    Run "mv /tmp/SUNWdetached.xml /zones/<new zone>"
    Run "zoneadm -z <new zone> attach"
    Run "zoneadm -z <new zone> boot -s"
    
    Run "zlogin -C <newzone>"
    Edit the /etc/nodename to reflect the new zone host name
    Edit /etc/hosts to ensure the loghost and name of the zone can be found in there with the correct
    ip address.
    Halt the zone and reboot it.
    
    All done!

 *=============================================================================================*

ENDOFMESSAGE
    
} # End PrintTarClone

#-----------------------------------------------------------------
# ReadParams:
# Read in values from build.params file to set actions 
#-----------------------------------------------------------------
ReadParams ()  {
   # Read the parameters file and set up for this run accordingly.
   if [ -f $PARAMSFILE ]; then
      LunName="`grep LunName $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      HostPrimary="`grep HostPrimary $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      HostSecndry="`grep HostSecndry $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      HostInstall="`grep HostInstall $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      HostTmplte="`grep HostTmplte $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"      
      MetaSet="`grep MetaSet $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      FlarImage="`grep FlarImage $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      ZoneType="`grep ZoneType $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      MetaDev="`grep MetaDev $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      MetaRoot="`grep MetaRoot $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      MetaMirr="`grep MetaMirr $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      IpAddress="`grep IpAddress $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      DefRouter="`grep DefRouter $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      Interface="`grep Interface $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      HostID="`grep HostID $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
      SysUnconfig="`grep SysUnconfig $PARAMSFILE | grep -v '^#' | awk -F: '{printf $2 }'`"
   else
      echo "No paramaters file exists! Please investigate."
      exit 1
   fi
} # End ReadParams
   
#-----------------------------------------------------------------
# ReadList:
# This sub creates a list of filesystems and sizes for soft partitions builds
# echo "Getting list of filesystems for build"
#-----------------------------------------------------------------
ReadList ()  {
   if [ "$INCLIST" ]; then
      cat $INCLIST | grep -v '^#' |grep -v '^$'
   else
      echo "I can't find the filesystems list file $INCLIST" ; exit 1
   fi
} # End ReadList

#-----------------------------------------------------------------
# PrintVfstab:
# Add following to vfstab
# May have to do header, body and footer
#-----------------------------------------------------------------
PrintVfstabHead () {
cat <<-ENDOFMESSAGE
#
# ----* Start : ${HostInstall} Solaris zone Metaset ${MetaSet} *----
#
/dev/md/${MetaSet}/dsk/${SoftPar}     /dev/md/${MetaSet}/rdsk/${SoftPar}    /zones/${HostInstall}   ufs     2       no      logging
ENDOFMESSAGE
} # End PrintVfstabHead

# -------------------------------------------------------------------------------------
# PrintVfstabLine / PrintVfstabLineYes
# Ensure the /abe line is commented in the vfstab so live upgrade does not go belly up
# -------------------------------------------------------------------------------------
PrintVfstabLine () {
if [ "$FSsystem" = "/abe" ] ; then
cat <<-ENDOFMESSAGE
# /dev/md/${MetaSet}/dsk/${SoftPar} /dev/md/${MetaSet}/rdsk/${SoftPar} /zones/${HostInstall}/fs${FSsystem}  ufs     2       no      logging
ENDOFMESSAGE
else
cat <<-ENDOFMESSAGE
/dev/md/${MetaSet}/dsk/${SoftPar} /dev/md/${MetaSet}/rdsk/${SoftPar} /zones/${HostInstall}/fs${FSsystem}  ufs     2       no      logging
ENDOFMESSAGE
fi
} # End PrintVfstabLine

PrintVfstabHeadYes () {
cat <<-ENDOFMESSAGE
#
# ----* Start : ${HostInstall} Solaris zone *----
#
/dev/md/dsk/${SoftPar}     /dev/md/rdsk/${SoftPar}    /zones/${HostInstall}   ufs     2       yes      logging
ENDOFMESSAGE
} # End PrintVfstabHeadYes


PrintVfstabLineYes () {
if [ "$FSsystem" = "/abe" ] ; then
cat <<-ENDOFMESSAGE
# /dev/md/dsk/${SoftPar} /dev/md/rdsk/${SoftPar} /zones/${HostInstall}/fs${FSsystem}  ufs     2       yes      logging
ENDOFMESSAGE
else
cat <<-ENDOFMESSAGE
/dev/md/dsk/${SoftPar} /dev/md/rdsk/${SoftPar} /zones/${HostInstall}/fs${FSsystem}  ufs     2       yes      logging
ENDOFMESSAGE
fi
} # End PrintVfstabLineYes

PrintVfstabFoot () {
cat <<-ENDOFMESSAGE
# ----* End   : ${HostInstall} Solaris zone *----
#
ENDOFMESSAGE
} # End PrintVfstabFoot

#-----------------------------------------------------------------
# PrintZoneCfgHead:
# Build the zone config file from scratch  and building "add fs" entries as
# needed.
#-----------------------------------------------------------------
PrintBrandZoneCfgHead () {
cat <<-ENDOFMESSAGE
create -t SUNWsolaris8
set zonepath=/zones/${HostInstall}
set brand=solaris8
set autoboot=true
set ip-type=shared
add attr
set name=machine
set type=string
set value=sun4u
end
ENDOFMESSAGE

if [ "${HostID}" ] ; then
cat <<-ENDOFMESSAGE
add attr
set name=hostid
set type=string
set value=${HostID}
end
ENDOFMESSAGE
fi

PrintZoneIps 

} # End  PrintBrandZoneCfgHead

PrintNativeZoneCfgHead () {
cat <<-ENDOFMESSAGE
create -b
set zonepath=/zones/${HostInstall}
set autoboot=true
set ip-type=shared
ENDOFMESSAGE
    
PrintZoneIps 

} # End  PrintNativeZoneCfgHead

PrintCloneZoneCfgHead () {
cat <<-ENDOFMESSAGE
create -b
set zonepath=/zones/${HostInstall}
set autoboot=true
set ip-type=shared
ENDOFMESSAGE

PrintZoneIps 

} # End  PrintCloneZoneCfgHead

# -------------------------------------------------------------------------------------
# PrintZoneCfgFS
# Ensure the /abe line is not added to zonecfg so live upgrade does not go belly up
# -------------------------------------------------------------------------------------
PrintZoneCfgFS () {
if [ ! "$FSsystem" = "/abe" ] ; then
cat <<-ENDOFMESSAGE
add fs
set dir=${FSmount}
set special=/zones/${HostInstall}/fs${FSsystem}
set type=lofs
add options [suid,nodevices,rw]
end
ENDOFMESSAGE
fi
} # End PrintZoneCfgFS 

# -------------------------------------------------------------------------------------
# PrintZoneIPs
# Process the IpAddress variable for a single or multiple comma seperated addresses
# These can only be to one interface/vlan
# -------------------------------------------------------------------------------------
PrintZoneIps () {
   IpAddress="`echo $IpAddress  | tr -s ',' ' ' `"
   for Addr in $IpAddress
   do
     cat <<-ENDOFMESSAGE   
add net
set address=${Addr}
set physical=${Interface}
set defrouter=${DefRouter}
end
ENDOFMESSAGE
   done
} # End PrintZoneIps 

#-----------------------------------------------------------------
# DoCmd:
# echo and run command and echo result.  Second line allows for script to run as comments only for debug.
#-----------------------------------------------------------------
DoCmd () { echo "Running: $CMD" ; eval $CMD ; [ $? -ne 0 ] && { echo "ERROR: Command Failed! Return code not zero!"  ; exit 1 ; } }
# DoCmd () { echo "Running: $CMD" ; }

#-----------------------------------------------------------------
# BuildTheZone:
# Stage IV/V Build the zone
# Create the zone. Install the zone from flar image (unconfigure, -u not -p, if renaming host for Branded Zones only)
# Save then config, Boot the zone, Connect to console and configure host, Check fs's and connectivity
#-----------------------------------------------------------------
BuildTheZone () {
   [ "$ZoneType" = "solaris8" ] && { CMD="PrintBrandZoneCfgHead >>${ZoneCFGFile}" ; DoCmd ; }
   [ "$ZoneType" = "native" ] && {  CMD="PrintNativeZoneCfgHead >>${ZoneCFGFile}" ; DoCmd ; }
   ReadList | while read FSmount FSsize
   do 
      if [ ! "$FSmount" = "/" ] 
      then
          if [ "`echo $FSmount | awk -F/ '{ print $3 }'`" ]
          then
             FSsystem='/'`echo $FSmount | sed 's/\///g'`
          else
             FSsystem=$FSmount
          fi
          CMD="PrintZoneCfgFS >>${ZoneCFGFile}" ; DoCmd
      fi
   done 
   CMD="${CHMOD} 700 /zones/${HostInstall}" ; DoCmd  
   # Configure zone
   CMD="zonecfg -z ${HostInstall} -f ${ZoneCFGFile}" ; DoCmd 
   echo "SysUnconfig is set to ${SysUnconfig}"
   # Install zone
   case "$ZoneType" in
      solaris8 ) [ "${SysUnconfig}" = "u" ] && { CMD="zoneadm -z ${HostInstall} install -u -a ${FlarImage}" ; DoCmd ; }
                 [ "${SysUnconfig}" = "p" ] && { CMD="zoneadm -z ${HostInstall} install -p -a ${FlarImage}" ; DoCmd ; }
                 ;;
        native ) CMD="zoneadm -z ${HostInstall} install ${FlarImage}" ; DoCmd 
                 ;;
             * ) echo "Unable to determine zone type! Please correct and re-run!" ; exit 1
                 ;;                      
   esac                                             
   CMD="${CHMOD} 755 /zones/${HostInstall}"/root ; DoCmd
   # Boot zone
   CMD="zoneadm -z ${HostInstall} boot -s" ; DoCmd
   echo "zlogin -C ${HostInstall} to check the config and fs mounts to complete build."
} # End BuildTheZone

#-----------------------------------------------------------------
# CloneTheZone:
# Stage IV Clone the zone
# Create the zone. Install the zone from template zone 
# Save then config, Boot the zone, Connect to console and configure host, Check fs's and connectivity
#-----------------------------------------------------------------
CloneTheZone () {
   if [ "$ZoneType" = "solaris8" ] ; then
      CMD="PrintBrandZoneCfgHead >>${ZoneCFGFile}" ; DoCmd      
   else
      CMD="PrintCloneZoneCfgHead >>${ZoneCFGFile}" ; DoCmd   
   fi   
   ReadList | while read FSmount FSsize
   do 
      if [ ! "$FSmount" = "/" ] 
      then
          if [ "`echo $FSmount | awk -F/ '{ print $3 }'`" ]
          then
             FSsystem='/'`echo $FSmount | sed 's/\///g'`
          else
             FSsystem=$FSmount
          fi
          CMD="PrintZoneCfgFS >>${ZoneCFGFile}" ; DoCmd
      fi
   done 
   CMD="${CHMOD} 700 /zones/${HostInstall}" ; DoCmd  
   # Configure zone
   echo "Configuring zone config file"
   CMD="zonecfg -z ${HostInstall} -f ${ZoneCFGFile}" ; DoCmd 
   
   # Install zone. Ensure template zone is down for cloning
   echo "Cloning zone ${HostTmplte} to new zone ${HostInstall}!"
   zoneadm list -vc | grep $HostTmplte | grep running
   [ $? -eq 0 ] && { echo "$HostTmplte is running, please shut it down" ; exit 1 ; }
   
   echo "If the cloning fails due to mounted filesystems, you may have to tar copy the zone to it's new home"
   PrintTarClone

   CMD="zoneadm -z ${HostInstall} clone ${HostTmplte}" ; DoCmd  
   CMD="${CHMOD} 755 /zones/${HostInstall}"/root ; DoCmd
   
   # Boot zone  into single user mode for final configs
   CMD="zoneadm -z ${HostInstall} boot -s" ; DoCmd
   echo "zlogin -C ${HostInstall} to check the config and fs mounts to complete build."
} # End CloneTheZone

#-----------------------------------------------------------------
# CreateMetset:
# Stage II  Create metset from lun
# Create metset soft partitions on lun
# Create the root filesystem partition and mount fs for remaining fs's to mount on.
#-----------------------------------------------------------------
CreateMetset () {
    CMD="${METASET} -s ${MetaSet} -a -h ${HostPrimary} ${HostSecndry}" ; DoCmd 
    CMD="${METASET} -s ${MetaSet} -a ${LunName}" ; DoCmd
    CMD="${METAINIT} -s ${MetaSet} ${MetaDev} 1 1 ${LunName}s0" ; DoCmd
    CMD="${METASTAT} -s ${MetaSet}" ; DoCmd
    CMD="${METASTAT} -ap" ; DoCmd
    
    ReadList | while read FSmount FSsize
    do 
       if [ "$FSmount" = "/" ] 
       then
          MetaNo01="`echo $MetaDev | sed 's/^.//'`" 
          SoftNo=`expr ${MetaNo01} + 1`  # Has to be root fs
          SoftPar=d${SoftNo}
          CMD="${METAINIT} -s ${MetaSet} ${SoftPar} -p ${MetaDev} ${FSsize}g" ; DoCmd
          CMD="echo y | ${NEWFS} /dev/md/${MetaSet}/dsk/${SoftPar}" ; DoCmd 
          [ ! -d "/zones/${HostInstall}" ] && { CMD="${MKDIR} /zones/${HostInstall}" ; DoCmd ; }
          CMD="${CHMOD} 700 /zones/${HostInstall}" ; DoCmd   
          # Now need entry to exist in vfstab or this fails
          PrintVfstabHead >>${Vfstab} 
          CMD="${MOUNT} /zones/${HostInstall}" ; DoCmd
          CMD="${MKDIR} /zones/${HostInstall}/fs" ; DoCmd
          CMD="${CHMOD} 755 /zones/${HostInstall}/fs" ; DoCmd   
       else
          CMD="${METAINIT} -s ${MetaSet} ${SoftPar} -p ${MetaDev} ${FSsize}g" ; DoCmd
          CMD="echo y | ${NEWFS} /dev/md/${MetaSet}/dsk/${SoftPar}" ; DoCmd
          # Test if line has more than one / and convert to nulls.
          # Need to understand goal here, eg /u01/app/oracle becomes u01apporacle for fs mount
          # But zone config sets fs special to mount as /u01/app/oracle inside zone.
          if [ "`echo $FSmount | awk -F/ '{ print $3 }'`" ]
          then
             FSsystem='/'`echo $FSmount | sed 's/\///g'`
          else
             FSsystem=$FSmount
          fi
          PrintVfstabLine >>${Vfstab} 
          CMD="${MKDIR} /zones/${HostInstall}/fs${FSsystem}" ; DoCmd
          [ ! "$FSsystem" = "/abe" ] && { CMD="${MOUNT} /zones/${HostInstall}/fs${FSsystem}" ; DoCmd ; }   
       fi
       # Send the current soft part details to md.tab
       # CMD="${METASTAT} -p ${SoftPar} | sed 1q  >> /etc/lvm/md.tab" ; DoCmd
       SoftNo=`expr ${SoftNo} + 1`  ; SoftPar=d${SoftNo}
    done 
    
    PrintVfstabFoot >>${Vfstab} 
    CMD="cat /etc/vfstab" ; DoCmd
    
    echo "# \n# Metaset definitions for zone on ${MetaSet} \n#" >> /etc/lvm/md.tab
    CMD="${METASTAT} -s ${MetaSet} -p >> /etc/lvm/md.tab" ; DoCmd
    CMD="cat /etc/lvm/md.tab" ; DoCmd
} # End CreateMetset

#-----------------------------------------------------------------
# CreateMetDev:
# Stage II  Create meta device from disk pair MetaRoot and MetaMirr
# Create metset soft partitions on meta device
# Create the root filesystem partition and mount fs for remaining fs's to mount on.
#-----------------------------------------------------------------
CreateMetDev () {
    # get devices and create mirror pair
    # Then send metastat -p output to md.tab
    MetaNo01="`echo $MetaDev | sed 's/^.//'`" 
    Disk1=`expr ${MetaNo01} + 1`  # Has to be root fs
    Disk2=`expr ${MetaNo01} + 2`  # Has to be root fs
    Disk1="d${Disk1}" ;    Disk2="d${Disk2}"
    CMD="${METAINIT} ${Disk1} 1 1 ${MetaRoot}" ; DoCmd
    CMD="${METAINIT} ${Disk2} 1 1 ${MetaMirr}" ; DoCmd
    CMD="${METAINIT} ${MetaDev} -m ${Disk1}" ; DoCmd
    CMD="${METATTACH} ${MetaDev} ${Disk2}" ; DoCmd
    CMD="${METASTAT} -p ${MetaDev}" ; DoCmd
    echo "# \n# Start definitions for zone ${HostInstall}\n#" >> /etc/lvm/md.tab
    CMD="${METASTAT} -p ${MetaDev} >> /etc/lvm/md.tab" ; DoCmd
    echo "# \n# Soft Partitions on ${MetaDev}\n#" >> /etc/lvm/md.tab
  
    ReadList | while read FSmount FSsize
    do 
       if [ "$FSmount" = "/" ] 
       then
          MetaNo01="`echo $MetaDev | sed 's/^.//'`" 
          SoftNo=`expr ${MetaNo01} + 3`  # Has to be root fs
          SoftPar=d${SoftNo}
          CMD="${METAINIT} ${SoftPar} -p ${MetaDev} ${FSsize}g" ; DoCmd
          CMD="echo y | ${NEWFS} /dev/md/dsk/${SoftPar}" ; DoCmd 
          [ ! -d "/zones/${HostInstall}" ] && { CMD="${MKDIR} /zones/${HostInstall}" ; DoCmd ; }
          CMD="${CHMOD} 700 /zones/${HostInstall}" ; DoCmd   
          # Now need entry to exist in vfstab or this fails
          PrintVfstabHeadYes >>${Vfstab} 
          CMD="${MOUNT} /zones/${HostInstall}" ; DoCmd
          CMD="${MKDIR} /zones/${HostInstall}/fs" ; DoCmd
          CMD="${CHMOD} 755 /zones/${HostInstall}/fs" ; DoCmd   
       else
          SoftPar=d${SoftNo}
          CMD="${METAINIT} ${SoftPar} -p ${MetaDev} ${FSsize}g" ; DoCmd
          CMD="echo y | ${NEWFS} /dev/md/dsk/${SoftPar}" ; DoCmd
          # Test if line has more than one / and convert to nulls.
          # Need to understand goal here, eg /u01/app/oracle becomes u01apporacle for fs mount
          # But zone config sets fs special to mount as /u01/app/oracle inside zone.
          if [ "`echo $FSmount | awk -F/ '{ print $3 }'`" ]
          then
             FSsystem='/'`echo $FSmount | sed 's/\///g'`
          else
             FSsystem=$FSmount
          fi
          PrintVfstabLineYes >>${Vfstab} 
          CMD="${MKDIR} /zones/${HostInstall}/fs${FSsystem}" ; DoCmd
          [ ! "$FSsystem" = "/abe" ] && { CMD="${MOUNT} /zones/${HostInstall}/fs${FSsystem}" ; DoCmd ; }
       fi
       # Send the current soft part details to md.tab
       CMD="${METASTAT} -p ${SoftPar} | sed 1q  >> /etc/lvm/md.tab" ; DoCmd
       SoftNo=`expr ${SoftNo} + 1` ; SoftPar=d${SoftNo}
    done 
    
    PrintVfstabFoot >>${Vfstab} 
    CMD="cat /etc/vfstab" ; DoCmd
    
    echo "# \n# End definitions for zone ${HostInstall}\n#" >> /etc/lvm/md.tab
    CMD="cat /etc/lvm/md.tab" ; DoCmd
} # End CreateMetDev

# *-----------------------------------
# Main
# *-----------------------------------

DATE="`DateStamp`"

ReadParams

cd /etc
cp -p vfstab vfstab.${DATE}
cp -p lvm/md.tab lvm/md.tab.${DATE}
ZoneCFGFile=/zones/${HostInstall}.cfg

selection=

until [ "$selection" = "0" ]; do
    PrintSelect
    read selection
    echo ""
    case $selection in
        1 ) echo "Run Option I : Display Options of Zone Creation on Metasets and Metadevs "
            PrintStages    ; PressEnter
            ;;
        2 ) echo "Run Option II : Create metaset and soft partitions"
            CreateMetset   ; PressEnter 
            ;;
        3 ) echo "Run Option III : Create meta devide and soft partitions"
            CreateMetDev   ; PressEnter 
            ;;
        4 ) echo "Run Option IV : Build the branded zone ${HostInstall}"
            BuildTheZone   ; PressEnter 
            ;;
        5 ) echo "Run Option V : Build the native zone ${HostInstall}"
            BuildTheZone   ; PressEnter 
            ;;            
        6 ) echo "Run Option VI : Clone a zone ${HostInstall}"
            CloneTheZone   ; PressEnter 
            ;;
        0 ) clear ; echo "\n\n\nAll Done! Thankyou for choosing an HP Company.\n\n" 
            PrintLast
            exit ;;
        * ) echo "Please enter numbers 1 to 6 or use 0 to Exit"; PressEnter ;;
    esac
done
exit 0  
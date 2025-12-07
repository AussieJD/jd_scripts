# This file is critical to the ZoneMetasetBuild.sh script as it supplies most
# of the info used in building the zone and filesystems on the metaset.
# LunName     - is the lun supplied by Enterprise storage to the servers to host the metaset
# HostPrimary and HostSecondary - list the two partner globals that will host the zone and metaset
# HostInstall - is the name of the zone to build  HostTmplte is the name of the zone to clone (if not using a flar)
# MetaDev     - is the first meta device to create on the metaset and the sost partitions will be created from this number
# ZoneType    - is the type of zone being created, eg Solaris 10 "native" or Branded "solaris8" zone
# HostID      - is the hostid value assigned to a branded zone so it retains the same hostid as the physical zone it is made from
# SysUnconfig - set the params to build a branded zone from a flar file and sysunconfig (-u) or preserve (-p) the hosts details
LunName     :c8t600601607360180056124A56B39EDF11d0
HostPrimary :adl1081
HostSecndry :   
HostInstall :adl0464
HostTmplte  :
MetaSet     :1226zone
MetaDev     :d300
MetaRoot    :c1t1d0s0
MetaMirr    :c1t3d0s0
# For extra virtual interfaces, add ip's seperated by commas.
IpAddress   :10.3.2.30
DefRouter   :10.3.2.1
Interface   :nxge3
ZoneType    :solaris8
FlarImage   :/zones/nfs/adl0464.flar
# Rest is ignored for cloning zones. Relevant to Sol8 Branded only
HostID      :8308de2e
# Following params determins if the zone will keep its host details (p) or
# be sysunconfig'd (u)
SysUnconfig :p

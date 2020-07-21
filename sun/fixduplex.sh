#!/bin/ksh
# copyright Jason Price
# Released under the GPL (GNU Public License)

# NOTICE: You use this script at your own risk.  I've had good luck with
# them, but I make no promises.

export PATH=/usr/bin:/sbin:/usr/sbin

# get a list of interfaces.  Lines with 'flags=' on them, also have
# the interface name on them.  Logical interface names (aka ones we
# don't care about) are named qfe0:0, so those are eliminated by the 
# cut -f 1 -d :, and the duplicates are removed by the sort -u.

# we only care about hme, qfe, eri and dmfe interfaces, since the others
# either don't have the problem by only supporting 10baseT, or are gigabit
# interfaces, which are special.  So, grep out the hme, eri and qfe ones
# into seperate lists, them wack off the hme, eri or qfe part to just have
# a list of numbers.
# NOTE: eri ports don't take the adv_* flags the same way.

if [ `id | awk '{print $1}'` != "uid=0(root)" ]; then
   echo "you must be root.  exiting."
   exit
fi

for iftype in qfe hme eri ; do
   curlist=`ifconfig -a | grep "flags=" | cut -f 1 -d : | sort -u | \
	grep $iftype | sed "s/${iftype}//g"`

   #echo iftype is $iftype and curlist is $curlist

   # the for loop won't work on an empty list.
   for instance in $curlist ; do
 	# set the instance of the interface
      ndd -set /dev/${iftype} instance $instance

	# get current state, and say if it's not 100mbit, or full duplex:
      speed=`ndd -get /dev/${iftype} link_speed`
      duplex=`ndd -get /dev/${iftype} link_mode`

      if [ "$speed" = "0" ]; then
         echo "${iftype}${instance} is at 10 mbit (!)"
      else
         echo "${iftype}${instance} is at 100 mbit"
      fi

      if [ "$duplex" = "0" ]; then
         echo "${iftype}${instance} is at half duplex (!)"
      else
         echo "${iftype}${instance} is at full duplex"
      fi

      if [ "$speed" = "0" -o "$duplex" = "0" ]; then
         ndd -set /dev/${iftype} adv_autoneg_cap 0
         ndd -set /dev/${iftype} adv_100T4_cap 0
         ndd -set /dev/${iftype} adv_100fdx_cap 1
         ndd -set /dev/${iftype} adv_100hdx_cap 0
         ndd -set /dev/${iftype} adv_10fdx_cap 0
         ndd -set /dev/${iftype} adv_10hdx_cap 0
      fi
   done

   case iftype in
     qfe )
        echo "Please add the following to /etc/system for qfe interfaces:"
        echo
        echo "*** the following will force 100mb full duplex on all qfe NICs"
        echo "set qfe:qfe_adv_autoneg_cap=0"
        echo "set qfe:qfe_adv_100T4_cap=0"
        echo "set qfe:qfe_adv_100fdx_cap=1"
        echo "set qfe:qfe_adv_100hdx_cap=0"
        echo "set qfe:qfe_adv_10fdx_cap=0"
        echo "set qfe:qfe_adv_10hdx_cap=0"
        echo
        ;;

     hme )
        echo "Please add the following to /etc/system for hme interfaces:"
        echo
        echo "*** the following will force 100mb full duplex on all hme NICs"
        echo "set hme:hme_adv_autoneg_cap=0"
        echo "set hme:hme_adv_100T4_cap=0"
        echo "set hme:hme_adv_100fdx_cap=1"
        echo "set hme:hme_adv_100hdx_cap=0"
        echo "set hme:hme_adv_10fdx_cap=0"
        echo "set hme:hme_adv_10hdx_cap=0"
        ;;

     eri )
        echo "Please add the following to /etc/system for eri interfaces:"
        echo
        echo "*** the following will force 100mb full duplex on all eri NICs"
        echo "* note: format for eri NICs is different from hme/qfe NICs"
        echo "set eri:adv_100fdx_cap=1"
        echo "set eri:adv_100hdx_cap=0"
        echo "set eri:adv_10fdx_cap=0"
        echo "set eri:adv_10hdx_cap=0"
        echo "set eri:adv_autoneg_cap=0"
        ;;
   esac

done

curlist=`ifconfig -a | grep "flags=" | cut -f 1 -d : | sort -u | grep dmfe`
# dmfe's work different.  You must give the full name/number to ndd, and
# not set it with 'ndd -set /dev/dmfe instance ?'.

for instance in $curlist ; do

   speed=`ndd -get /dev/${instance} link_speed`
   duplex=`ndd -get /dev/${instance} link_mode`

   if [ "$speed" = "0" -o "$speed" = "10" ]; then
      echo "${instance} is at 10 mbit (!)"
   else
      echo "${instance} is at 100 mbit"
   fi

   if [ "$duplex" = "0" ]; then
      echo "${instance} is at half duplex (!)"
   else
      echo "${instance} is at full duplex"
   fi

   if [ "$duplex" = "0" -o "$speed" = "0" ]; then
      ndd -set /dev/${instance} adv_100fdx_cap 1
      ndd -set /dev/${instance} adv_100hdx_cap 0
      ndd -set /dev/${instance} adv_10fdx_cap 0
      ndd -set /dev/${instance} adv_10hdx_cap 0
      ndd -set /dev/${instance} adv_autoneg_cap 0
   fi

   echo
   echo "Note: You can not set the speed and duplex settings for dmfe ports"
   echo "in /etc/system.  It is set in:"
   echo
   echo "/platform/SUNW,UltraAX-i2/kernel/drv/dmfe.conf"
   echo
   echo "Uncomment the 'speed' and 'full-duplex' lines, and you'll force it"
   echo "too 100 megabit/full duplex"
done

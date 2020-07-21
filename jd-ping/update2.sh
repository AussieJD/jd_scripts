#!/bin/bash

## . /data/rrd/etc/rrd.conf
. rrd2.conf

## UPDATECMD=$(ping -c 3 -w 6 $HOST | grep rtt | awk -F "/" '{ print $5 }' )
UPDATECMD=$(/sbin/ping -c 3 -t 6 $HOST | grep round-trip | awk -F "/" '{ print $5 }' )

$RRDTOOL update $FILE N:$UPDATECMD


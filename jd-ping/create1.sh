#!/bin/bash

## . /data/rrd/etc/rrd.conf
. rrd.conf

$RRDTOOL create $FILE -s 60 \
DS:ping:GAUGE:120:0:200 \
RRA:AVERAGE:0.5:1:6000

#!/bin/bash

## . /data/rrd/etc/rrd.conf
. rrd3.conf

$RRDTOOL create $FILE -s 60 \
DS:ping:GAUGE:120:0:100 \
RRA:AVERAGE:0.5:1:6000

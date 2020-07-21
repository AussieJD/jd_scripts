#!/bin/bash

. rrd.conf

function ping1(){
$RRDTOOL create $FILE -s 60 \
DS:ping:GAUGE:120:0:200 \
RRA:AVERAGE:0.5:1:6000
}

. rrd2.conf

function ping2(){
$RRDTOOL create $FILE -s 60 \
DS:ping:GAUGE:120:0:100 \
RRA:AVERAGE:0.5:1:6000
}

. rrd3.conf

function ping3(){
$RRDTOOL create $FILE -s 60 \
DS:ping:GAUGE:120:0:100 \
RRA:AVERAGE:0.5:1:6000
}

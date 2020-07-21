#!/bin/bash

. ./rrd.conf

$RRDTOOL graph $OUTPUT \
        -t "iMac 27 --> $HOST  - Ping" -v "Time in ms" \
        --start="now-1d" \
        --end="now" \
        --height="120" \
        --width="900" \
        -c "BACK#000000" \
        -c "SHADEA#000000" \
        -c "SHADEB#000000" \
        -c "FONT#DDDDDD" \
        -c "CANVAS#202020" \
        -c "GRID#666666" \
        -c "MGRID#AAAAAA" \
        -c "FRAME#202020" \
        -c "ARROW#FFFFFF" \
        "DEF:ping_time=$FILE:ping:AVERAGE" \
        "CDEF:shading2=ping_time,0.98,*" "AREA:shading2#F90000:$HOST" \
        "GPRINT:ping_time:LAST:Last\: %5.2lf ms" \
        "GPRINT:ping_time:MIN:Min\: %5.2lf ms" \
        "GPRINT:ping_time:MAX:Max\: %5.2lf ms" \
        "GPRINT:ping_time:AVERAGE:Avg\: %5.2lf ms" \
        "CDEF:shading10=ping_time,0.90,*" "AREA:shading10#E10000" \
        "CDEF:shading15=ping_time,0.85,*" "AREA:shading15#D20000" \
        "CDEF:shading20=ping_time,0.80,*" "AREA:shading20#C30000" \
        "CDEF:shading25=ping_time,0.75,*" "AREA:shading25#B40000" \
        "CDEF:shading30=ping_time,0.70,*" "AREA:shading30#A50000" \
        "CDEF:shading35=ping_time,0.65,*" "AREA:shading35#960000" \
        "CDEF:shading40=ping_time,0.60,*" "AREA:shading40#870000" \
        "CDEF:shading45=ping_time,0.55,*" "AREA:shading45#780000" \
        "CDEF:shading50=ping_time,0.50,*" "AREA:shading50#690000" \
        "CDEF:shading55=ping_time,0.45,*" "AREA:shading55#5A0000" \
        "CDEF:shading60=ping_time,0.40,*" "AREA:shading60#4B0000" \
        "CDEF:shading65=ping_time,0.35,*" "AREA:shading65#3C0000" \
        "CDEF:shading70=ping_time,0.30,*" "AREA:shading70#2D0000" \
        "CDEF:shading75=ping_time,0.25,*" "AREA:shading75#180000" \
        "CDEF:shading80=ping_time,0.20,*" "AREA:shading80#0F0000" \
        "CDEF:shading85=ping_time,0.15,*" "AREA:shading85#000000" >/dev/null
cp $OUTPUT /Library/Webserver/Documents

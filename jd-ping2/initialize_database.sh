### change to the script directory
#cd /tools/rrdtool/latency/

rrdtool create latency_db.rrd \
--step 60 \
DS:pl:GAUGE:120:0:100 \
DS:rtt:GAUGE:120:0:10000000 \
RRA:MAX:0.5:1:6000 \


#!/bin/sh
#
#


x=`df -k | grep UVH`
[ $? -eq "1" ] 	&&	[ ! -d /export/home/cz0qk6/UVH ] && mkdir /export/home/cz0qk6/UVH \
		&& 	mount 139.73.190.4:/migration1 /export/home/cz0qk6/UVH \
		||	

#create flash archive: (on physical)
flarcreate -S -n aubwsacc003-full -x /export/home/cz0qk6/UVH \
        /export/home/cz0qk6/UVH/vcc/aubwsacc003/aubwsacc003-test-2014-04-12.flasharchive




# The End!

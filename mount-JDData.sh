#!/bin/bash
#
# mount afp 192.168.1.99 /JDData on /Volumes/JDData
#  and make sure it's being indexxed by Spotlight (mdworker)
#
clear
[ -d /Volumes/test ] 			&& echo "/Volumes/test exists" \
					|| echo "/Volumes/test does not exist" 

[ `mount | grep \"/Volumes/test\"` ]	&& `echo \"/Volumes/test is mounted\"` \
                                        || echo "/Volumes/test is not mounted"

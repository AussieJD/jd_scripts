#!/bin/sh
#
UVH-MENU=yes
UVH-NAME="UVH disks"
UVH-DESCRIPTION="See all visible disks using the format command"

echo "# all disks visible on host using format command"
echo | format | grep ". c0" | awk '{print $1,",",$2,",",$12}' | while read line
 do
        N=`uname -n`
        echo $N, $line
done
# The End

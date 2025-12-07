#!/bin/bash

for device in $( fcinfo logical-unit | awk '{print $4}' ) 
do 
echo "----------------" 
echo $device 
luxadm -v display $device | grep Serial 
done

# The End!

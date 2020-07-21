#!/bin/bash
#
# Remove files in .Trash and .Trashes in all mounted drives
#
## find all mounted volumes and parse the "pathnames" into a list
clear
echo ============================= =
sudo ls

for i in ` df -h | grep Volumes | awk '{ print $6}'`
 do
	echo "--- Checking $i"
#	if [ -d .Trash ]; then rm -r .Trash/*;fi
	if [ -d $i/.Trash ]
	 then 	
		echo " * - found $i/.Trash - removing"
		echo "found `sudo ls $i/.Trash | wc -l` files"
#		sudo rm -r $i/.Trash/*
	 else 
		echo "  - $i/.Trash not found .... skipping"
	fi

	if [ -d $i/.Trashes ]
	 then 	
		echo "* - found $i/.Trashes - removing"
		echo "found `sudo ls $i/.Trashes | wc -l` files"
#		sudo rm -r $i/.Trashes/*
	 else 
		echo "  - $i/.Trashes not found .... skipping"
	fi
done

## look in each of the mounted partitions for .Trash* folders
## ... and if .Trash* is found, remove files within
## ... and if .Trash is NOT found, skip folder and move on




# The End!

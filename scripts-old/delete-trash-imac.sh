#!/bin/bash
#
# Remove files in .Trash and .Trashes in all mounted drives
#
## find all mounted volumes and parse the "pathnames" into a list
clear
echo ============================= =
sudo ls
	if [ -d ~/.Trash ]
	 then 	
		echo "  --- ~/.Trash exists - removing files"
		echo "  --- removing `sudo ls $i/.Trash | wc -l` files"
		sudo find ~/.Trash
		sudo rm -r ~/.Trash/
	 else 
		echo " -------------------------- - $i/Users/jon/.Trash not found .... skipping"
	fi

for i in ` df -h | grep Volumes | awk '{ print $6}'`
 do
	echo "--- $i"
	if [ -d $i/.Trash ]
	 then 	
		echo "  --- $i/.Trash exists - removing files"
		echo "  --- removing `sudo ls $i/.Trash | wc -l` files"
		sudo find $i/.Trash
		sudo rm -r $i/.Trash/
	 else 
		echo " -------------------------- - $i/.Trash not found .... skipping"
	fi

	if [ -d $i/.Trashes ]
	 then 	
		echo " --- $i/.Trashes exists - removing files"
		echo " --- removing `sudo ls $i/.Trashes | wc -l` files"
		sudo find $i/.Trashes
		sudo rm -r $i/.Trashes/
	 else 
		echo "  ------------------------- $i/.Trashes not found .... skipping"
	fi
sleep 1
done

## look in each of the mounted partitions for .Trash* folders
## ... and if .Trash* is found, remove files within
## ... and if .Trash is NOT found, skip folder and move on




# The End!

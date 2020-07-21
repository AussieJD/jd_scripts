#!/bin/bash
#

get()
{ 
rsync -avuzb --exclude "*~" /Volumes/jon-bak/jon/Documents/testing/ /Volumes/JD/Documents/testing 
}
#{ rsync -avuzb /Volumes/jon-bak/jon/Documents/testing `ls | grep -v work` }

put()
{ 
rsync -Cavuzb /Volumes/JD/Documents/testing/ /Volumes/jon-bak/jon/Documents/testing
}
#{ rsync -Cavuzb `ls | grep -v work`  /Volumes/jon-bak/jon/Documents }

# script

df -h | grep jon-bak >> /dev/null 2>&1 &&
{	
echo "jon-bak is mounted. Beginning rsync!"
	cd ~/Documents/testing
	get;put;
} || 
{ 
echo "jon-bak not currently mounted. Please mount and try again." ; 
}

# end script

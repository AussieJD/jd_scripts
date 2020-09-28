#!/bin/bash 
# 
# 
#
# Synopsis:	bi-directional sync two directories, but with no deletes
#		ie. a file deleted in one of the directories
#		will be replaced by the copy at the next sync
#

# variables
DIR1=/Volumes/JD			# dirctory one
DIR2=/Volumes/jon-bak/jon	# directory two
EXCLUDE="Movies" 					# only one please (fix later!)

get()
{ 
rsync -avuzb --exclude="${EXCLUDE}" $DIR2/ $DIR1
}

put()
{ 
rsync -avuzb --exclude="${EXCLUDE}" $DIR1/ $DIR2
}

# script

df -h | grep jon-bak >> /dev/null 2>&1 &&
{	
echo "jon-bak is mounted. Beginning rsync!"
cd ~/Documents/testing
#	get
put
umount ~/Documents/work-remote
} || 
{ 
echo "jon-bak not currently mounted. Please mount and try again." ; 
}


# end script

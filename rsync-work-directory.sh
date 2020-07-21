#!/bin/bash 
#
# Synopsis:	bi-directional sync two directories, but with no deletes
#		ie. a file deleted in one of the directories
#		will be replaced by the copy at the next sync
#
# variables
DIR1=/Volumes/JD/Documents/work			# dirctory one
DIR2=/Volumes/JD/Documents/work-remote/work	# directory two
EXCLUDE="" 					# only one please (fix later!)

# echo a Disclaimer.....
echo " -------- WARNING: delete from both to ensure full delete --------"
echo " -------- WARNING: add to MAC to ensure sync --------"

get()
{ 
rsync -avuzb --exclude="${EXCLUDE}" $DIR2/ $DIR1
#rsync -navuzb --delete --exclude="${EXCLUDE}" $DIR2/ $DIR1
}

put()
{ 
rsync -avuzb --delete --exclude="${EXCLUDE}" $DIR1/ $DIR2
#rsync -navuzb --delete --exclude="${EXCLUDE}" $DIR1/ $DIR2
}

unmountit()
{
ls
}

mountit()
{
ls
}

# script

# is the nfs server (adelaide) visible
ping -c 1 adelaide >> /dev/null 2>&1 &&

# if yes, mount the required directory
{ 
mount_nfs -s adelaide:/export/share/User/jd51229 ~/Documents/work-remote 
} || { 

# tell us if the server is not available, and quit
echo "adelaide not available. Stopping rsync." 
exit 1
}

# check to make sure that the remote (nfs) directory has been sucessfiully mounted
df -h | grep work-remote >> /dev/null 2>&1 &&

# if nfs folder mounted, then run the rsync get and rsync put
{
put
#get
umount ~/Documents/work-remote
} || {

# if nfs mount is not there, exit 
echo ".. mount seems to be missing... exiting"
exit 1
}

# end script

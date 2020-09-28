df -h | grep jon-bak >> /dev/null 2>&1
if [ $? = "0" ]
 then
	echo "jon-bak is mounted. Beginning rsync!"
	cd ~/Documents
	rsync -Cavz `ls | grep -v work` /Volumes/jon-bak/jon/Documents
 else
	echo "jon-bak not currently mounted. Please mount and try again."
fi

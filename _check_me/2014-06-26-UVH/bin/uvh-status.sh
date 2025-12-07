#!/usr/bin/bash


# VARIABLES #########################################

#LIST="auszvuvh001 auszvuvh002 auszvuvh003 auszvuvh004 auszvuvh005 auszvuvh006"
#LIST="auszvuvh001 auszvuvh002 auszvuvh003 auszvuvh004 auszvuvh005 "	# removed 006 for BAU testing
LIST="auszvuvh001 auszvuvh004"	# 6-Mar-2014 removed 002, 003, 005

#UVH_MENU=yes						# stub for a future "menu" feature - currently unused
#UVH_NAME="Check UVH status"				# stub for a future "menu" feature - currently unused
#UVH_DESCRIPTION="Check where zones and metasets are"	# stub for a future "menu" feature - currently unused

BASE=/UVH/bin
SNAP_USER=root
SCRIPTFILE=uvh-status-script.out

# SCRIPT #############################################

#clear

if [[ `/usr/ucb/whoami` != "root" ]]; then
	echo "this script must be run as root" 2>&1
	exit 1
fi


for server in $LIST
 do
	printf "Current Zone Status: $server ========================================================= \n"
#	printf "... copying $BASE/$SCRIPTFILE \n"
        SSH_VAR="ssh $SNAP_USER@$server"
        echo "`cat $BASE/$SCRIPTFILE | $SSH_VAR "cat > /tmp/snapshot ; chmod 775 /tmp/snapshot; /tmp/snapshot; rm /tmp/snapshot"&`"
done
#The End!


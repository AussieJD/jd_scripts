#!/bin/bash

    trap shutdown SIGTERM

    function shutdown()
    {
#		/usr/bin/VBoxManage controlvm ${VMNAME} savestate
		/usr/bin/VBoxManage controlvm "HP COE" savestate
		exit 0
    }

# 	/usr/bin/VBoxHeadless --startvm ${VMNAME} &
	/usr/bin/vboxmanage startvm "HP COE" &
    wait $!

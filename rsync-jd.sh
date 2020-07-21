#!/bin/bash
#
# Summary:	JD's rsync script
#		- common variables for rsync to do an inplace sync of large files
#		
clear
echo " This will perform an rsync "
rsync -pv --inplace --progress JD-32813.asiapacific.hpqcorp.net.vdi /Virtualbox-disks/

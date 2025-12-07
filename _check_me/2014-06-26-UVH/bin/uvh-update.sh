#!/bin/sh
# ensure local copies of uvh-boot and uvh-master are up-to-date

LIST="auszvuvh001 auszvuvh002 auszvuvh004 auszvuvh005"

BMF=/UVH/bin/uvh-boot.sh
BLF=/etc/rc3.d/S99uvh

MMF=/UVH/etc/uvh-master
MLF=/usr/local/etc/uvh-master

for i in $LIST
do
	echo "checking / updating $BMF and $MMF on $i"
	CMD="cmp -s $BMF $BLF || ( ls -l $BLF ; cp $BMF $BLF ; ls -l $BLF )"
	ssh $i "$CMD"
	CMD="cmp -s $MMF $MLF || ( ls -l $MLF ; cp $MMF $MLF ; ls -l $MLF )"
	ssh $i "$CMD"
done

exit 0

PATH=/bin:/usr/bin:/usr/sbin
WHO=`who am i | awk '{ print $1}'`
( echo "Directory listing for $WHO, `date`\n"
echo "Total:\t`du -sk $HOME`\n"
echo "By files and directories:\n"
du -s $HOME/* ) | mailx -s "Directory Size for $WHO"  jon@adelaide

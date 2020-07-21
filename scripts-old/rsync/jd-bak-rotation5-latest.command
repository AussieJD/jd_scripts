#rotating backup script - v1.0
echo "starting backup script"
echo "###### moving folders, removing oldest"
rm -rf "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.2"
mv -f "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.1" "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.2"
mv -f "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.0" "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.1"
echo "###### Linking new *copy*"
cd /Volumes/iMac-Share1/JD-bak-rotate/jd-bak.1 && find . | cpio -dpl /Volumes/iMac-Share1/JD-bak-rotate/jd-bak.0
echo "###### syncing new *copy*"
time /usr/local/bin/rsync --rsync-path=/usr/local/bin/rsync -vaz -P --delete "/Users/jon" "/Volumes/iMac-Share1/JD-bak-rotate/jd-bak.0/"

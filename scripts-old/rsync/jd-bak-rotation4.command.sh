#rotating backup script - v1.0
echo "starting backup script"
echo "###### moving folders, removing oldest"
rm -rf "/Volumes/MAC/JD-bak-rotate/jd-bak.4"
mv -f "/Volumes/MAC/JD-bak-rotate/jd-bak.3" "/Volumes/MAC/JD-bak-rotate/jd-bak.4"
mv -f "/Volumes/MAC/JD-bak-rotate/jd-bak.2" "/Volumes/MAC/JD-bak-rotate/jd-bak.3"
mv -f "/Volumes/MAC/JD-bak-rotate/jd-bak.1" "/Volumes/MAC/JD-bak-rotate/jd-bak.2"
mv -f "/Volumes/MAC/JD-bak-rotate/jd-bak.0" "/Volumes/MAC/JD-bak-rotate/jd-bak.1"
echo "###### Linking new *copy*"
cd /Volumes/MAC/JD-bak-rotate/jd-bak.1 && find . | cpio -dpl /Volumes/MAC/JD-bak-rotate/jd-bak.0
echo "###### syncing new *copy*"
time /usr/local/bin/rsync --rsync-path=/usr/local/bin/rsync -vaz -P --delete "/Users/jon" "/Volumes/MAC/JD-bak-rotate/jd-bak.0/"

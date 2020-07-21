#rotating backup script - v1.0
rm -rf "/Volumes/fred/JD-bak-rotate/jd-bak.4"
mv -f "/Volumes/fred/JD-bak-rotate/jd-bak.3" "/Volumes/fred/JD-bak-rotate/jd-bak.4"
mv -f "/Volumes/fred/JD-bak-rotate/jd-bak.2" "/Volumes/fred/JD-bak-rotate/jd-bak.3"
mv -f "/Volumes/fred/JD-bak-rotate/jd-bak.1" "/Volumes/fred/JD-bak-rotate/jd-bak.2"
mv -f "/Volumes/fred/JD-bak-rotate/jd-bak.0" "/Volumes/fred/JD-bak-rotate/jd-bak.1"
cd /Volumes/fred/JD-bak-rotate/jd-bak.1 && find . | cpio -dpl /Volumes/fred/JD-bak-rotate/jd-bak.0
time /usr/local/bin/rsync --rsync-path=/usr/local/bin/rsync -vaz -P --delete --showtogo "/Volumes/JD" "/Volumes/fred/JD-bak-rotate/jd-bak.0/"

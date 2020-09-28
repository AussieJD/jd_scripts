if [ -f /tmp/modems.online.out ]
then
	rm /tmp/modems.online.out
for i in `ypcat hosts | grep 129.158.144 | awk ' { print $2 }'`
do
ping $i 1 | grep $i >> /tmp/modems.online.out
done
cat /tmp/modems.online.out | grep "no answer"
cat /tmp/modems.online.out | grep alive

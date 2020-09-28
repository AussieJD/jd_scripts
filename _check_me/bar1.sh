#/bin/bash
for i in `seq $1`
do
if [ `expr $i % $2` -eq 0 ]
then
echo -n "|"
fi
done
echo " $1"

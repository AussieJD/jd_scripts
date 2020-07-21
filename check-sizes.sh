#!/bin/bash
#
file=rsync-logs.out
count=1
ratecount=0
ratesum=0
sizecount=0
sizetotal=0
sizetotalm=0
sizetotalg=0
expectedsize=356197976
expectedsizeg=$(( $expectedsize / 1000 / 1000 ))

cat $file | while read line
 do
        [[ `echo $line | grep ^sent` ]]         && rate=`echo $line | grep ^sent| awk '{print $7}' | cut -f1 -d.` \
                                                && ratek=$(( $rate / 1000 )) \
                                                && ratecount=$(( $ratecount + 1 )) \
                                                && ratesum=$(( $ratesum + $rate )) \
                                                && rateav=$(( $ratesum / $ratecount / 1000 )) \
                                                && printf "%-3s %-7s %-5s %-5s %-13s %-6s %-3s \n" $ratecount rate: $ratek "kb/s" Average-rate: $rateav "kb/s"

        [[ `echo $line | grep ^total` ]]        && size=`echo $line | grep ^total | awk '{print $4}'`  \
                                                && sizem=$(( $size / 1000 / 1000 )) \
                                                && sizetotalm=$(( $sizetotalm + $sizem )) \
                                                && sizetotalg=$(( $sizetotalm / 1000 )) \
                                                && sizecount=$(( $sizecount + 1 )) \
                                                && printf "%-3s %- 7s %-5s %-5s %-13s %-6s %-5s %-3s %-3s \n" $sizecount Size: $sizem MB Total-size: $sizetotalm MB $sizetotalg GB \
                                                && percentage=`echo $sizetotalg/$expectedsizeg | bc`
done
        echo "Expected size: $expectedsizeg GB ($percentage %)"

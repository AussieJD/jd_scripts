#!/bin/sh

F=/migration5/vcc/outage2
T=/zones/fs
K="/export/home/kev/bin/ksnap -f -m -v"

k()
{
	$K $1 $2 | egrep -v "^[a-z]|descend|creat|remove|mode|owner|times|unlink|compared|link" | grep .
}

# for H in aubwsacc004 aubwsacc008 aubwsacc015 aubwsacc018
# do
#	echo "`date`: $H acc"
#	k $F/$H/acc $T/$H/var-acc
#	echo "`date`: $H cust"
#	k $F/$H/cust $T/$H/cust
#	echo "`date`: $H home"
#	k $F/$H/home $T/$H/export-home
#	echo "`date`: $H lc"
#	k $F/$H/lc $T/$H/lc
# done

H=aubwsacc007
CMD="mv $F/$H/app/oracle/backup/APPAMS1 $F/$H/APPAMS1"
echo $CMD
$CMD
echo "`date`: $H app"
k $F/$H/app $T/$H/app
CMD="mv $F/$H/APPAMS1 $F/$H/app/oracle/backup/APPAMS1"
echo $CMD
$CMD
for D in 1a 2a cust u01 u02 u03 u04 u05 u06
do
	echo "`date`: $H $D"
	k $F/$H/$D $T/$H/$D
done
echo "`date`: done"

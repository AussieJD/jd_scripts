# j.driscoll ksh  15-May-1998
#
# Usage: search $HOME/Mail using grep
#
# search $HOME/Mail, $HOME/Mail/general, $HOME/Mail/old
# for keywords using 'grep' 
#
debug=n
#
user=`id | cut -d\( -f2 | cut -d\) -f1`
machine=`uname -n`
ip=`cat /etc/hosts | grep $machine | awk '{ print $1 }'|head -1|cut -d. -f1-2`
if [ $debug = "y" ];then echo "user =$user, machine=$machine, ip=$ip"
echo "Press any key to continue...\c"
read start
fi
if [ $user != "jon" ];then echo "..not logged on as jon. Exiting...";exit 1;fi
if [ $ip != "129.158" ];then echo "
You must be logged on as jon and on a SWAN machine for this script to work sanely
..machine not on SWAN. Exiting..."
exit 1;fi
#
clear
echo "\n Please enter the string you want to serch for...> \c"
read WHAT
echo " /n ...searching $HOME/Mail, $HOME/Mail/general, $HOME/Mail/old .... \n"
grep "${WHAT}" /home/staff/jon/Mail/* |more
grep "${WHAT}" /home/staff/jon/Mail/general/* |more
grep "${WHAT}" /home/staff/jon/Mail/old/* |more










#!/bin/ksh
#------------------------------------------------------------------------
#
# uprstat - Show user's memory usage
# 
# Reads the passwd file and attempts to get information from 
# ypmatch (NIS).
#
# Submitted by: Scott Gillespie
#
#------------------------------------------------------------------------

print_border() {
  hostname_length=`hostname | wc -c`
  str="+"

  i=0
  while [ $i -lt $hostname_length+3 ]; do
     printf "%s" $str
     let i=$i+1
  done
}

# Get the readable username via ypmatch
get_readable_usernm() {
    readable_user=`ypmatch $user passwd \
| awk -F":" '{print $5}' | sed 's/\(.*\)\(.*\),\(.*\)/\1/g' \
| awk -F" " '{print $1" "$2" "$3}' \
| sed 's/\(.*\)\[\(.*\)/\1/g'`
}
 
for i in 1 2 3; do
  if [ $i -ne 2 ]; then
     print_border
  else
     echo "\n\n+ `hostname` +\n"
  fi
done
echo "\n"

# Get the user sizes
get_user_sizes() {

  for user in `who | awk '{print $1}' | sort | uniq`; do

     a=`ypmatch $user passwd >>/dev/null 2>&1; echo $?`
     b=`grep $user /etc/passwd >>/dev/null 2>&1; echo $?`

     if [[ ( $a != 0 ) && ( $b != 0 ) ]]; then
        :
     else
        size_K=`prstat -u $user 1 1 | awk '{ if ($3 ~ /K/) print $3 }' \
              | sed 's/K//g' | awk '{total=0; $total += $0; print $total}' \
              | tail -1`
               
        size_M=`prstat -u $user 1 1 | awk '{ if ($3 ~ /M/) print $3 }' \
           | sed 's/M//g' | awk '{total=0; $total += $0; print $total}' \
           | tail -1`

            if [[ ( $size_K > 0 ) && ( $size_M > 0 ) ]]; then
           size_M_in_K=`expr $size_M \* 1000`  
              size_All=`expr $size_M_in_K + $size_K`
                    total_MB=`expr $size_All / 1000`
           get_readable_usernm
              echo "mem: $total_MB MB\tuser: $readable_user"
        fi

               if [[ ( $size_K > 0 ) && ( $size_M == "" ) ]]; then
                  total_MB=`expr $size_K / 1000`
           get_readable_usernm
           echo "mem: $total_MB MB\tuser: $readable_user"
        fi

        if [[ ( $size_K == "" ) && ( $size_M > 0 ) ]]; then
           get_readable_usernm
           echo "mem: $total_MB MB\tuser: $readable_user"
        fi
     fi
  done
}

# Flow
get_user_sizes | sort -t " " -k 2,2n
echo "\nTOTAL: `get_user_sizes | awk '{ total=0; $total+=$2; print $total}' | tail -1` MB\n" 

### Exit
exit 0;

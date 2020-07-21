#!/bin/ksh
#
# File name     : license.sh
#
# Author        : Brodie James 
#
# Date          : 09 December 1999
#
# Description   :
#
# Gets the SunPro compiler license file from http://seinfo.aus
#
# Usage         : license.sh
#
# Modifications :
#
#
# Essential Information:
#
#
debug="n"
url="http://seinfo.aus/license/license.dat"
ofile="/export/install/license.dat"
#
# Get the file with wget
#
/usr/local/bin/wget -O $ofile $url
#
# The End!
#

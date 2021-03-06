#!/bin/sh

#####################################################################
#
# Example CGI script to launch Squid Graph to generate a report
#
# Supplementary tool for Squid Graph v3
#
# We *REALLY* do not recommend the use of this. It is provided
# for the convinience of those who wants to use Squid Graph
# as a CGI application
#
# Usage:
#   http://www.some.server.com/generate.cgi?<password>
#
# Please refer to the Squid Graph v3 documentation for more info
# http://squid-graph.sourceforge.net/
#
#####################################################################

#
# Set a password
#
PASS=nopass

#
# Where's your Squid logfile?
#
LOGFILE=/usr/local/squid/logs/access.log

#
# Output directory
#
OUTPUT_DIR=/tmp

#
# Other options (do NOT include --output-dir)
#
OPTIONS="--tcp-only --no-transfer-duration"

#
# Prefix -- where is Squid Graph installed?
#
PREFIX=/usr/local/squid-graph

### DO NOT TOUCH THIS ###

echo "Content-type: text/plain"
echo ""

if test "$QUERY_STRING" = "$PASS"
then
	if test ! -f $LOGFILE
	then
		echo "The file $LOGFILE does not exist!"
		exit
	elif test ! -d $OUTPUT_DIR
	then
		echo "The directory $OUTPUT_DIR does not exist!"
		exit
	else
		$PREFIX/bin/squid-graph -o=$OUTPUT_DIR $OPTIONS < $LOGFILE
		exit
	fi
else
	echo "The password is incorrect!"
	exit
fi

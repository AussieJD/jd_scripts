#!/bin/sh
#
# This software is Copyright (C) 1995 Computer Smiths Pty Ltd.
# Unauthorised use prohibited.
#
# This script attempts to build a /etc/named.boot, and named files for
# a site, given the following information...
#
PATH=/usr/bin:/usr/sbin:/sbin:/bin:/usr/local/bin:/usr/contrib/bin:/usr/X11/bin
LOCAL_DOMAIN=`domainname`
if [ -z "$LOCAL_DOMAIN" -a -f /etc/resolv.conf ]
then
        LOCAL_DOMAIN=`grep domain /etc/resolv.conf | awk '{ print $2 }'`
fi
if [ ! -z "$LOCAL_DOMAIN" ]
then
	case "$LOCAL_DOMAIN" in
	*.)
		;;
	*)
		LOCAL_DOMAIN="$LOCAL_DOMAIN".
		;;
	esac
fi
POSTMASTER=postmaster
MX_FILE=/tmp/default_mx.$$
DIR=/var/named
COMPANY_NAME=""
PRIMARY_IP=""
NS_1_NAME=""		# ns.$LOCAL_DOMAIN
NS_1_IP=""		# 1.1.1.1
NS_2_NAME=""		# ns.other.dom.ain.
NS_2_IP=""		# 1.1.1.2
NS_F_IP=""		# forwarding IP address
MAIL_IP=""		# 1.1.1.4
SERVER=""		# server.$LOCAL_DOMAIN
HOSTS=""		# /etc/hosts
#
# Misc Routines
#
question()
{
	echo "$1\c"
}

yes_no()
{
	while :
	do
		question "$1 (y|n) [y] ? "
		read YN
		case "X$YN" in
		X|Xy|XY)
			return 0
			;;
		Xn|XN)
			return 1
			;;
		*)
			echo Unparsable input '"'$YN'"'
			;;
		esac
	done
}

get_info()
{
	Q=$1
	A=$2
	while :
	do
		question "$Q [$A] ? " 1>&2
		read ANS
		if [ -z "$ANS" ]
		then
			ANS="$A"
		fi
		if [ -z "$ANS" ]
		then
			echo "Invalid Null Response" 1>&2
		else
			break
		fi
	done
	echo "$ANS"
}

get_dot_info()
{
	Qd=$1
	Ad=$2
	while :
	do
		ANS=`get_info "$Qd" "$Ad"`
		case "$ANS" in
		*.)
			break
			;;
		*)
			yes_no "$ANS." 1>&2
			case $? in
			0)
				ANS=$ANS.
				break
				;;
			*)
				continue
				;;
			esac
		esac
	done
	echo "$ANS"
}

get_data()
{
	#
	# Ask the qppropriate questions...
	#
	COMPANY_NAME=`get_info	"Enter The Company Name" ""`
	LOCAL_DOMAIN=`get_dot_info	"Enter Local Domain Name" "$LOCAL_DOMAIN"`
	FOR_FILE=`echo $LOCAL_DOMAIN | sed 's/\(.*\)./\1/'`
	NS_1_NAME=`get_dot_info	"Enter Fully Qualified Primary Name Server Name" "ns.$LOCAL_DOMAIN"`
	NS_1_IP=`cat /etc/hosts | sed 's/#.*//' | grep $NS_1_NAME | sed 1q`
	NS_1_IP=`get_info	"Enter IP Number for $NS_1_NAME" "$NS_1_IP"`
	NS_2_NAME=`get_dot_info "Enter Fully Qualified Secondary Name Server Name" ""`
	NS_2_IP=`cat /etc/hosts | sed 's/#.*//' | grep $NS_2_NAME | sed 1q`
	NS_2_IP=`get_info	"Enter IP Number for $NS_2_NAME" "$NS_2_IP"`
	yes_no "Forward unknown queries"
	case $? in
	0)
		NS_F_IP=`get_info "Enter IP number to forwared unknown queries to" "$NS_2_IP"`
		;;
	esac
	yes_no "Reverse lookups wanted"
	case $? in
	0)
		REVADDR=`echo $NS_1_IP | sed 's/\(.*\)\.\(.*\)\.\(.*\)\..*/\3.\2.\1.in-addr.arpa./'`
		REVADDR=`get_dot_info "Enter Fully qualified reverse address" "$REVADDR"`
		REVFILE=`echo $REVADDR | sed 's/\(.*\)\./\1/'`
		;;
	esac
	POSTMASTER=`get_info	"Enter postmaster destination" "$POSTMASTER"`
	SERVER=`get_dot_info	"Primary www/ftp/news server" "$LOCAL_DOMAIN"`
	PRIMARY_IP=`get_info	"Enter IP Number for $SERVER" "$NS_1_IP"`
	MAIL_IP=`get_info	"Enter IP Number for Mail Server" "$PRIMARY_IP"`
	DIR=`get_info		"Directory for Name Server Files" "$DIR"`
	make_directory
}
	
entry_mx()
{
	cat <<!EOF
You have to entry the Mail eXchange (MX) values for the domain.

This involves entering a priority and fully qualified domain name for each mail
machine. We will be creating an alias mail.$LOCAL_DOMAIN that you can use for
the local mail machine.

Enter the priority and mail exchange host, one per line.
E.g. 0 mail.$LOCAL_DOMAIN
     10 second_mail.$LOCAL_DOMAIN

A blank entry, or priority of "q", will terminate the list.
!EOF
	while :
	do
		question "? "
		read priority name
		if [ -z "$priority" -o "q" = "$priority" ]
		then
			break
		fi
		case $name in
		*.)
			;;
		*.*)
			yes_no "$name."
			case $? in
			0)
				name=$name.
				;;
			*)
				echo "Ignoring Entry"
				continue
				;;
			esac
			;;
		*)
			yes_no "$name.$LOCAL_DOMAIN"
			case $? in
			0)
				name=$name.$LOCAL_DOMAIN
				;;
			*)
				echo "Ignoring Entry"
				continue
				;;
			esac
			;;
		esac
		echo "		IN	MX	$priority $name" >> $MX_FILE
	done
}

#
# Generate soa record
#
make_soa()
{
	echo ";"
	echo "; Zone file for $LOCAL_DOMAIN for $COMPANY_NAME"
	echo "; Created `date` by build_named"
	echo ";"
	echo "; Please ensure records are sorted by IP address."
	echo ";"
	echo "@	IN	SOA	$NS_1_NAME	$POSTMASTER.mail.$LOCAL_DOMAIN ("
	echo "			`date +%Y%m%d01`	; Serial Number (date YYYYMMDD++)"
	echo "			10800		; Refresh (3 hours)"
	echo "			1800		; Retry (1/2 hour)"
	echo "			3600000		; Expire (42 days)"
	echo "			21600)		; Minimum (6 hours)"
}

#
# Generate NS records
#
make_ns()
{
	echo ";"
	echo "; Name Servers"
	echo ";"
	echo "	IN	NS	$NS_1_NAME"
	echo "	IN	NS	$NS_2_NAME"
	echo "$NS_1_NAME	IN	A	$NS_1_IP"
	echo "$NS_2_NAME	IN	A	$NS_2_IP"
}

#
# Generate a primary entry for the domain.
# This is the address to which the local domain defaults.
#
make_default_mx()
{
	echo ";"
	echo "; Default A and MX for $LOCAL_DOMAIN"
	echo ";"
	echo "$LOCAL_DOMAIN	IN	A	$PRIMARY_IP"
	cat $MX_FILE
}

make_directory()
{
	if [ ! -d $DIR ]
	then
		yes_no "Create $DIR"
		case $? in
		0)
			mkdir -p $DIR
			case $? in
			0)
				;;
			*)
				yes_no "Directory Creation failed - Abort"
				case $? in
				0)
					exit 1
					;;
				esac
				;;
			esac
			;;
		esac
	fi
}
			
make_forward()
{
	#
	# create the file for the forward (ie, name to number) file.
	#
	echo "Creating domain file for $FOR_FILE"
	FILE="$DIR"/"$FOR_FILE"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	make_soa > $FILE
	make_ns >> $FILE
	make_default_mx >> $FILE
	question 'Take hosts from a hosts file? [/etc/hosts] '
	read HOSTS
	if [ -z "$HOSTS" ]
	then
		HOSTS=/etc/hosts
	fi
	cat >>$FILE <<!EOF
;
; Aliases and Canonical Names for Various Services
;
ftp	IN	CNAME	$SERVER
www	IN	CNAME	$SERVER
news	IN	CNAME	$SERVER
ntp	IN	CNAME	$SERVER
;
; Mail is a special case - it cannot be a CNAME, it must be an IP number.
;
mail	IN	A	$MAIL_IP
!EOF
	cat $MX_FILE >>$FILE
	if [ -r "$HOSTS" ]
	then
		cat >>$FILE <<!EOF
;
; Records from Host server
;
!EOF
		grep -v '^#' "$HOSTS" | sed 's/#.*//' | while read number name aliases
		do
			case $name in
			*.)
				;;
			*.*)
				name=$name.
				;;
			*)
				;;
			esac
			echo "$name	IN	A	$number"
			cat $MX_FILE
			for i in $aliases
			do
				case $i in
				*.)
					;;
				*.*)
					i=$i.
					;;
				*)
					;;
				esac
				echo "$i	IN	CNAME	$name"
			done
		done >> $FILE
	fi
}

make_cache()
{
	FILE="$DIR"/"root.cache"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	cat >$FILE <<!EOF
;
; Root cache file for $LOCAL_DOMAIN nameserver
;
; The only entries we need is that for the nameservemachines
;
.			99999999	IN	NS	$NS_1_NAME
.			99999999	IN	NS	$NS_2_NAME
;
; Add the addresses for these machines.
$NS_1_NAME		99999999	IN	A	$NS_1_IP
$NS_2_NAME		99999999	IN	A	$NS_2_IP
!EOF
}

make_localhost()
{
	echo "Creating localhost reverse lookup"
	FILE="$DIR"/"0.0.127.in-addr.arpa"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	make_soa > $FILE
	make_ns >> $FILE
	echo "1	IN	PTR	localhost." >> $FILE
}

make_reverse()
{
	if [ -z "$REVADDR" ]
	then
		return
	fi
	echo "Creating reverse domain file for $FOR_FILE ($REVADDR)"
	FILE="$DIR"/"$REVFILE"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	make_soa > $FILE
	make_ns >> $FILE
	NUM=`echo "$REVADDR" | sed 's/\([0-9.]*\).*/\1/'`
	case $NUM in
	*.*.*)
		NUM=`echo $NUM | sed 's/\(.*\)\.\(.*\)\.\(.*\)\..*/\3.\2.\1/'`
		;;
	*.*)
		NUM=`echo $NUM | sed 's/\(.*\)\.\(.*\)\..*/\2.\1/'`
		;;
	esac
	cat >>$FILE <<!EOF
;
; PTR Resource information - number to name maps.
;
!EOF
	if [ -r "$HOSTS" ]
	then
		cat >>$FILE <<!EOF
;
; Records from Host server
;
!EOF
		grep -v '^#' "$HOSTS" | sed 's/#.*//' | grep "^${NUM}." | sed "s/^${NUM}.//" | while read number name aliases
		do
			case $name in
			*.)
				;;
			*.*)
				name=$name.
				;;
			*)
				name=$name.$LOCAL_DOMAIN
				;;
			esac
			echo "$number	IN	PTR	$name"
		done >> $FILE
	fi

}

make_named_boot()
{
	FILE="$DIR"/"named.boot"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	case "$DIR" in
	/*)
		DIR_LOC="$DIR"
		;;
	*)
		DIR_LOC=`pwd`"/$DIR"
		;;
	esac
	cat >$FILE <<!EOF
;
; Boot file for $LOCAL_DOMAIN nameserver
;
directory	$DIR_LOC
cache		.		root.cache
;
; We are the primary for the following
;
primary		$FOR_FILE	$FOR_FILE
primary		0.0.127.in-addr.arpa	0.0.127.in-addr.arpa
!EOF
	if [ ! -z "$REVADDR" ]
	then
		echo "primary		$REVFILE	$REVFILE" >> $FILE
	fi
	yes_no "Are we a secondary for any domains"
	case $? in
	0)
		cat >>$FILE <<!EOF
;
; We secondary the following
;
!EOF
		cat <<!EOF
You have to entry the Domain Names and the IP address(es) of the server(s)
for the domain.
Enter the name, followed by the IP addresses of the servers. E.g. if we
are a secondsry for cc.berkley.edu you would enter:

cc.berkeley.edu 10.2.0.78 128.32.0.10

A blank entry, or name of "q", will terminate the list.
!EOF
		while :
		do
			question "? "
			read name ipaddrs
			if [ -z "$name" -o "q" = "$name" ]
			then
				break
			fi
			if [ -z "$ipaddrs" ]
			then
				echo The list of addresses cannot be blank.
				continue
			fi
			case $name in
			*.)
				;;
			*.*)
				yes_no "$name."
				case $? in
				0)
					name=$name.
					;;
				*)
					echo "Ignoring Entry"
					continue
					;;
				esac
				;;
			*)
				yes_no "$name.$LOCAL_DOMAIN"
				case $? in
				0)
					name=$name.$LOCAL_DOMAIN
					;;
				*)
					echo "Ignoring Entry"
					continue
					;;
				esac
				;;
			esac
			echo "secondary	$name	$ipaddrs" >> $FILE
		done
		;;
	esac
	if [ ! -z "$NS_F_IP" ]
	then
		cat >> $FILE <<!EOF
;
; Forward Queries
;
forwarders	$NS_F_IP
!EOF
	fi
	yes_no "Install boot file as /etc/named.boot"
	case $? in
	0)
		if [ -f /etc/named.boot ]
		then
			mv /etc/named.boot /etc/named.boot.orig
			echo "/etc/named.boot saved in /etc/named.boot.orig"
		fi
		cp "$DIR"/named.boot /etc/named.boot
		;;
	esac
}

make_resolv_conf()
{
	echo "Creating /etc/resolv.conf"
	FILE="/etc/resolv.conf"
	if [ -f $FILE ]
	then
		mv $FILE $FILE.orig
		echo "$FILE saved in $FILE.orig"
	fi
	echo "domain	$FOR_FILE" > $FILE
	echo "nameserver	127.0.0.1" >> $FILE
	chmod 644 $FILE
}

get_data
entry_mx
make_forward
make_cache
make_reverse
make_localhost
make_named_boot
make_resolv_conf
rm -f $MX_FILE


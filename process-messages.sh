#!/bin/sh
#
# 2024 Eric Radman <ericshane@eradman.com>
#
# Process new messages to allow users to manage mailing list membership
# using simple OpenSMPTD tables.

: ${READ_MESSAGE:="/usr/local/libexec/smtpd/read_message.awk"}
: ${MEMBERS:="/etc/mail/members"}
: ${ALIASES:="/etc/mail/aliases"}
: ${MAILDIR:="mail"}
: ${PROJECT:="rset"}
: ${LIST_NAME:="dev"}
: ${LIST_EMAIL:="dev@scriptedconfiguration.org"}
: ${ADMIN_EMAIL:="admin@scriptedconfiguration.org"}

function commit {
	doas cp tmp/members.new $MEMBERS
	doas rsub $ALIASES <<-CONF
	$LIST_NAME: /var/www/archive/$PROJECT-$LIST_NAME-$(date +%Y).mbox,marc,$(paste -sd ',' $MEMBERS)
	CONF
	rm -f tmp/members.new rsub_*
	doas smtpctl update table aliases
	doas smtpctl update table members
}

function send_status {
	reply_to=$1
	if egrep -xq $reply_to $MEMBERS; then
		msg="You are subscribed to $LIST_EMAIL"
	else
		msg="You are not subscribed to $LIST_EMAIL"
	fi
	echo "$msg" | mail -r $ADMIN_EMAIL -s "Re: status $LIST_NAME" $reply_to
}

# backup
cp $MEMBERS etc/members.$(md5 -q $MEMBERS)

export LIST_NAME
export IFS="|"
$READ_MESSAGE $(find $MAILDIR/new -type f -name "*.*.*") /dev/null \
| while read -r list email action msgfile
do
	case $action in
		subscribe)
			egrep -xv $email $MEMBERS > tmp/members.new
			echo $email >> tmp/members.new
			commit
			;;
		unsubscribe)
			egrep -xv $email $MEMBERS > tmp/members.new
			commit
			;;
		status)
			send_status $email
			;;
	esac

	mv $msgfile $MAILDIR/cur/
done

# wait for incoming messages
echo $MAILDIR/new | entr -zpnd true
[ $? -eq 0 -o $? -eq 2 ] && exec $0 $*

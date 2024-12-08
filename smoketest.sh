#!/bin/sh
set -a

PATH="$PWD/test/stubs:$PATH"
READ_MESSAGE="$PWD/read_message.awk"
MEMBERS="$PWD/test/etc/mail/members"
ALIASES="$PWD/test/etc/mail/aliases"
MAILDIR="test/home/mail"
WATCHFILE="/dev/null"
LIST_NAME="dev"

function try {
	printf "\e[7m$*\e[27m\n"
	rm -f etc/*
	git checkout $MEMBERS $ALIASES 2> /dev/null
}

function memberdiff {
	for etc in $(find etc -type f); do
		diff -u $etc $MEMBERS
	done
}

# setup
mkdir -p $MAILDIR/{tmp,new,cur}
mkdir -p etc tmp
mv $MAILDIR/new/* $MAILDIR/cur/

try "add list headers"
./add_list_headers.awk < test/opensmtpd-data.in

try "read messages"
./read_message.awk test/home/mail/cur/*

try "subscribe command"
mv $MAILDIR/cur/1708978889.9004ffbf.hub1.scriptedconfiguration.org:2,RS $MAILDIR/new/
sh -u process-messages.sh
memberdiff

try "unsubscribe command"
echo "tech@eradman.com" >> $MEMBERS
mv $MAILDIR/cur/1718310671.86d68cae.hub1.scriptedconfiguration.org:2,S $MAILDIR/new/
sh -u process-messages.sh
memberdiff

try "status command"
mv $MAILDIR/cur/1718310759.9d6ca6b9.hub1.scriptedconfiguration.org:2,S $MAILDIR/new/
sh -u process-messages.sh
memberdiff

try "no remaining messages"
find $MAILDIR/new -type f

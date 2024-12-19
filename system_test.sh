#!/bin/sh
set -a

PATH="$PWD/test/stubs:$PATH"
READ_MESSAGE="$PWD/read_message.awk"
MEMBERS="$PWD/test/etc/mail/members"
ALIASES="$PWD/test/etc/mail/aliases"
MAILDIR="test/home/mail"
WATCHFILE="/dev/null"
LIST_NAME="dev"
RSUB_DIFF_ARGS=" "

function reset {
	rm -f etc/*
	git checkout $MEMBERS $ALIASES 2> /dev/null
	find $MAILDIR/new -type f -exec mv {} $MAILDIR/cur/ \;
}

function try {
	printf '.'
	expected="test/expected/$(printf "$1" | tr -c '[:alnum:]' '_')"
}

function memberdiff {
	for etc in $(find etc -type f); do
		diff $etc $MEMBERS
	done
}

function check {
	git diff --exit-code $expected.* || exit 1
	let tests+=1
}

# setup
mkdir -p $MAILDIR/{tmp,new,cur}
mkdir -p etc tmp

try "add list headers"
	./add_list_headers.awk < test/opensmtpd-data.in > $expected.out
	check

try "read messages"
	reset
	./read_message.awk test/home/mail/cur/* > $expected.out
	check

try "subscribe command"
	reset
	mv $MAILDIR/cur/1708978889.9004ffbf.hub1.scriptedconfiguration.org:2,RS $MAILDIR/new/
	sh -u process-messages.sh > $expected.out
	memberdiff > $expected.diff
	check

try "unsubscribe command"
	reset
	echo "tech@eradman.com" >> $MEMBERS
	mv $MAILDIR/cur/1718310671.86d68cae.hub1.scriptedconfiguration.org:2,S $MAILDIR/new/
	sh -u process-messages.sh > $expected.out
	memberdiff > $expected.diff
	check

try "status command"
	reset
	mv $MAILDIR/cur/1718310759.9d6ca6b9.hub1.scriptedconfiguration.org:2,S $MAILDIR/new/
	sh -u process-messages.sh > $expected.out
	memberdiff > $expected.diff
	check

try "no remaining messages"
	reset
	find $MAILDIR/new -type f > $expected.out
	check

echo
echo "$tests tests PASSED"

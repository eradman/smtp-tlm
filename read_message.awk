#!/usr/bin/awk -f
# USAGE:
#   read_message.awk [msg, ...]
#
# Print a one-line summary for each input file

BEGIN {
	OFS="|"
	list_name=ENVIRON["LIST_NAME"]
}

/^Return-Path: / {
	sub("<", "")
	sub(">", "")
	email=$NF
}
/^Subject: (subscribe|unsubscribe|status) [a-z]+$/ {
	if ($3 == list_name) action=$2
}

# email body
$0 == "" {
	if (list_name && email && action)
		print list_name, email, action, FILENAME
	nextfile
}

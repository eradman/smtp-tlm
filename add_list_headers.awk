#!/usr/bin/awk -f
# USAGE:
#   filter <filter-name> proc-exec "/path/to/add_list_headers.awk"
#
# OpenSMTPD filter that adds List-* headers
# Inspired by https://github.com/jirutka/opensmtpd-filter-rewrite-from

BEGIN {
	FS = "|"
	OFS = FS
	_ = FS
	in_body[""] = 0
}

"config|ready" == $0 {
	print("register|filter|smtp-in|data-line")
	print("register|ready")
	fflush()
	next
}
"config" == $1 {
	next
}
"filter" == $1 {
	if (NF < 7) {
		print("invalid filter command: expected >6 fields!") > "/dev/stderr"
		exit 1
	}
	sid = $6
	token = $7
	line = substr($0, length($1$2$3$4$5$6$7) + 8)

	# continue with next rule...
}
"filter|smtp-in|data-line" == $1_$4_$5 {
	if (line == "") {  # end of headers
		in_body[sid] = 1
	}
	if (!in_body[sid] && match(toupper(line), /^FROM:[\t ]*/)) {
		# Sneak in the extra headers
		print("filter-dataline", sid, token, "List-Id: <dev.scriptedconfiguration.org>")
		print("filter-dataline", sid, token, "List-Post: <mailto:dev@scriptedconfiguration.org>")
		print("filter-dataline", sid, token, "List-Owner: <mailto:ericshane@eradman.com> (Eric Radman)")
		print("filter-dataline", sid, token, "List-Unsubscribe: <mailto:admin@scriptedconfiguration.org?subject=unsubscribe+dev>")
		print("filter-dataline", sid, token, "List-Help: <mailto:admin@scriptedconfiguration.org?subject=list+help>")
		print("filter-dataline", sid, token, "Precedence: list")
	}
	if (line == ".") {  # end of data
		delete in_body[sid]
	}
	print("filter-dataline", sid, token, line)
	fflush()
	next
}

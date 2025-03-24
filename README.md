SMTP Tiny List Manager
======================

A tiny email list manager for OpenSMTPD.

Inspired by the minimalist list manager used by d78.org.

Dependencies
------------

* doas
* entr
* rset

Configuration
-------------

*/etc/doas.conf*

    permit nopass admin as root cmd cp args tmp/members.new /etc/mail/members
    permit nopass admin as root cmd rsub args /etc/mail/aliases
    permit nopass admin as root cmd smtpctl args update table aliases
    permit nopass admin as root cmd smtpctl args update table members

*/etc/mail/smtpd.conf*

    smtp max-message-size 1M

    table aliases file:/etc/mail/aliases
    table members file:/etc/mail/members

    filter "add_list_headers" proc-exec "/usr/local/libexec/smtpd/add_list_headers.awk"

    listen on localhost port 25
    listen on egress inet4 tls pki letsencrypt filter "add_list_headers"

    action "local" maildir "%{user.directory}/mail" alias <aliases>
    action "outbound" relay helo scriptedconfiguration.org

    match from any for rcpt-to "admin@scriptedconfiguration.org" action "local"
    match !from mail-from <members> for domain "scriptedconfiguration.org" reject
    match from any for domain "scriptedconfiguration.org" action "local"
    match from local for local action "local"
    match from local for any action "outbound"

Installation
------------

    for dir in bin etc tmp log; do
        install -d -o admin /home/admin/$dir
    done
    mkdir /usr/local/libexec/smtpd
    install -m 755 -o admin process-messages.sh /home/admin/bin/
    install -m 755 add_list_headers.awk /usr/local/libexec/smtpd/
    install -m 755 read_message.awk /usr/local/libexec/smtpd/

Verification
------------

    telnet scriptedconfiguration.org 25

    EHLO vm.eradman.com
    MAIL FROM: <eradman@eradman.com>
    RCPT TO: <dev@scriptedconfiguration.org>
    RSET
    QUIT

This should return one of two responses

    250 2.1.5 Destination address valid: Recipient ok
    550 Invalid recipient: <dev@scriptedconfiguration.org>

Caveats
-------

* Multiple lists not supported
* Two-step verification not implemented

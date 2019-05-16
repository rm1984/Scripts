#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nmap_amap_identify.sh <TARGET>
#
# Description:  A script that tries to discover the real services running behind
#               the open ports on a target host.
#
# Usage:        ./nmap_amap_identify.sh <TARGET>
#
#
# --TODO--
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
"amap"
"nmap"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

IP=$1
TMPFILE=$(mktemp -q)

nmap -sS -v -O --open ${IP} -oG ${TMPFILE} &>/dev/null

cat ${TMPFILE} | grep 'Ports:' | cut -d':' -f3 | sed -e 's/, /\n/g' | grep open | cut -d'/' -f1

for PORT in $(cat ${TMPFILE} | grep 'Ports:' | cut -d':' -f3 | sed -e 's/, /\n/g' | grep open | cut -d'/' -f1) ; do
    amap -q -U ${IP} ${PORT} | grep matches
done

rm -f ${TMPFILE}


#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        tor_check.sh
#
# Description:  A script that checks for Tor connectivity via command line.
#
# Usage:        ./tor_check.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

HOST=localhost
PORT=9050
CHECK_SITE="https://check.torproject.org/"
EXIT_NODE="http://checkip.amazonaws.com/"
#EXIT_NODE="http://ipecho.net/plain"


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"curl"
"netstat"
);

for CMD in ${CMDS[@]} ; do
    command_exists$CMD
done


# MAIN -------------------------------------------------------------------------

TOR_STRING=$(netstat -plantue | grep LISTEN | grep ${PORT})

if [[ -z "${TOR_STRING}" ]] ; then
    echo "Tor service doesn't seem to be running (since nothing is listening on port ${PORT})..."
else
    curl --socks5 ${HOST}:${PORT} --socks5-hostname ${HOST}:${PORT} -s ${CHECK_SITE} | cat | grep -m 1 Congratulations | xargs

    EXIT_NODE_IP=$(curl --socks5-hostname ${HOST}:${PORT} -s ${EXIT_NODE})

    echo "Tor seems to be up! Your current exit node's IP is: ${EXIT_NODE_IP}"
fi

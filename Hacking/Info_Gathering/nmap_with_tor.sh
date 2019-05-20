#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nmap_with_tor.sh <TARGET>
#
# Description:  A script that lets users run full TCP port scans with NMap
#               anonymously through the TOR network. TOR and ProxyChains must be
#               installed, and the TOR daemon must be running.
#
# Usage:        ./nmap_with_tor.sh <TARGET>
#
# Notes:        Please make sure that your TOR configuration file has the
#               following lines:
#
#                   SOCKSPort              9050
#                   AutomapHostsOnResolve  1
#                   DNSPort                53530
#                   TransPort              9040
#
#               and that your ProxyChains configuration file has the following
#               lines:
#
#                   dynamic_chain
#                   proxy_dns
#                   tcp_read_time_out 15000
#                   tcp_connect_time_out 8000
#                   [ProxyList]
#                   socks5 127.0.0.1 9050
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

declare -a CMDS=(
"nmap"
"proxychains"
"tor"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

TARGET=$1
OUT="/tmp/${TARGET}.out"

if [[ ! -z ${TARGET} ]] ; then
    proxychains nmap -4 -sT -Pn -n -vv --open -oG ${OUT} ${TARGET}
else
    >&2 echo "Error! <TARGET> not specified."
        echo "Usage: ./$(basename $BASH_SOURCE) <TARGET>"
fi

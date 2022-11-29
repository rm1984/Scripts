#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        get_nics_with_ip_mac_status_freebsd.sh
#
# Description:  A script that returns a list of all the NICs with their IP and
#               MAC addresses plus their status. Works on FreeBSD only.
#
# Usage:        ./get_nics_with_ip_mac_status_freebsd.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}

display_usage() {
    echo "Usage: $0"
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"ifconfig"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ $# -ne 0 ]] ; then
    display_usage

    exit 1
else
    echo
    echo "Interface | MAC address          | IP address           | Status"
    echo "----------+----------------------+----------------------+-----------"

    for IF in $(ifconfig -l) ; do
        MA=$(ifconfig $IF | grep -w ether | awk '{print $2}')
        IP=$(ifconfig $IF | grep -w inet | awk '{print $2}')
        ST=$(ifconfig $IF | grep -w status | cut -d':' -f2)

        printf "%-9s | %-20s | %-20s |%-20s" "$IF" "$MA" "$IP" "$ST"
        echo
    done

    echo
fi

#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        get_nics_with_ip_mac_status.sh
#
# Description:  A script that returns a list of all the NICs with their IP and
#               MAC addresses plus their status.
#
# Usage:        ./get_nics_with_ip_mac_status.sh
#
#
# --TODO--
# - Fix code to get NICs list on RHEL 7
# - Add support for other Unix systems
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
"ip"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ $# -ne 0 ]] ; then
    display_usage

    exit 1
else
    # The following command *does not* work on RHEL 7 (ifconfig output format has changed)
    #for NIC in $(ifconfig -a | sed 's/[ \t].*//;/^\(lo\|\)$/d;/:/d') ; do
    for NIC in $(ifconfig -s | grep -v Iface | awk '{print $1}' | grep -v lo | grep -v inet6) ; do
        MAC=$(ip addr show $NIC | grep 'link/ether' | awk '{print $2}')
        STATUS=$(ip -4 addr show $NIC | grep -o 'state [^ ,]\+' | sed 's/state\ //g')

        if [[ "$STATUS" != "UP" ]] ; then
            printf "%-20s %-18s %-10s %-8s\n" $MAC " " $NIC $STATUS
        else
            printf "%-20s %-18s %-10s %-8s\n" MAC IP NIC STATUS
            echo "------------------------------------------------------------"

            while read -r ROW ; do
                IP=$(echo $ROW | awk '{print $2}' | sed 's/\/.*//')
                IFACE=$(echo $ROW | awk 'NF>1{print $NF}')

                printf "%-20s %-18s %-10s %-8s\n" $MAC $IP $IFACE $STATUS
            done < <(ip -4 addr show $NIC | grep inet)
        fi
    done
fi

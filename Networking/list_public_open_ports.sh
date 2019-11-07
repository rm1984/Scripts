#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        list_public_open_ports.sh
#
# Description:  This script lists all the listening processes that expose one or
#               more open ports on a server's public IP. All those open ports
#               may represent a potential attack surface.
#               It uses "sockstat" and has been tested on FreeBSD only.
#
# Usage:        ./list_public_open_ports.sh
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


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"column"
"curl"
"sockstat"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

IP=$(curl -s ifconfig.co) # get public IP address

{
echo "USER PROCESS PORT"
echo "---- ------- ----"
sockstat -4 -l | grep -e "\*:[0-9]" -e $IP | awk '{ print $1," ",$2," ",$6 }' | sed -e 's/*://g' | sed -e "s/$IP://g" | sort -u
} | column -t -x


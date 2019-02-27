#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nmap_light.sh
#
# Description:  A script that performs a light scan againt a subnet, and saves
#               the output in a greppable text file.
#
# Usage:        ./nmap_light.sh <SUBNET>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

SUBNET=$1


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
"nmap"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if  [[ ! -z $SUBNET ]] ; then
    OUTFILE=$(echo "nmap_$SUBNET.txt" | tr '/' '_')

    nmap -sS -v -O --open -oG ${OUTFILE} ${SUBNET}
else
    >&2 echo "Error! <SUBNET> not specified."
        echo "Usage: ./$(basename $BASH_SOURCE) <SUBNET>"
fi

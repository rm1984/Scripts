#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nmap_deep.sh
#
# Description:  A script that performs a deep, complete and aggressive NMAP scan.
#
# Usage:        /nmap_deep.sh <target>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

TARGET=$1


# FUNCTIONS --------------------------------------------------------------------

check_cmd () {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" >&2 ; exit 1 ; }
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
    check_cmd $CMD
done


# MAIN -------------------------------------------------------------------------

if  [[ ! -z $TARGET ]] ; then
    nmap -vv -Pn -sS -A -sC -p- -T 3 -script-args=unsafe=1 -n ${TARGET}
else
    >&2 echo "Error! <target> not specified."
        echo "Usage: ./$(basename $BASH_SOURCE) <target>"
fi

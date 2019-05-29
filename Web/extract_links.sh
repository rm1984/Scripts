#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        extract_links.sh
#
# Description:  A script that extracts all the web links from the HTML page
#               source of a given website.
#
# Usage:        ./extract_links.sh <url>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

URL=$1
HTML=/tmp/.page.$RANDOM.html

# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"curl"
"lynx"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ -z "${URL}" ]] ; then
    echo "Error! <url> not specified."

    exit 1
fi

curl -s -k ${URL} -o ${HTML}
lynx -dump -hiddenlinks=listonly ${HTML} | grep -vF 'file://' | grep "^\ .[0-9]*\.\ http" | awk '{ print $2 }' | sort -u
rm -f ${HTML}


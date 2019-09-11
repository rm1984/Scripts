#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        pwd_sucker_hashkiller.sh
#
# Description:  A script that fetches cracked passwords from the following site:
#               https://hashkiller.co.uk/
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

URL="https://hashkiller.co.uk/"
DICT_DIR=~/DICTIONARIES
DICT=$DICT_DIR/CUSTOM_hashkiller.txt


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"wget"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

[[ $DEBUG -ne 0 ]] && set -x

OUT_HTML=$(echo /tmp/.rnd-${RANDOM}.html)

wget $URL -O $OUT_HTML
cat $OUT_HTML | grep -F '</span></td>' | grep -vF '<td><span' | awk '{print $1}' >> $DICT

sort -u $DICT -o $DICT

rm -f $OUT_HTML $OUT_CSV

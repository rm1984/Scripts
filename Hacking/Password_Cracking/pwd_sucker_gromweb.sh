#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        pwd_sucker_gromweb.sh
#
# Description:  A script that fetches cracked passwords from the following site:
#               https://md5.gromweb.com/
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

URL="https://md5.gromweb.com/"
DICT_DIR=~/DICTIONARIES
DICT=$DICT_DIR/CUSTOM_gromweb.txt


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
cat $OUT_HTML | grep -F '<a href="/?string=' | cut -d'=' -f3 | cut -d'"' -f1 >> $DICT

sort -u $DICT -o $DICT

rm -f $OUT_HTML $OUT_CSV

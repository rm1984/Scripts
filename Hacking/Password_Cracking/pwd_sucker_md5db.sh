#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        pwd_sucker_md5db.sh
#
# Description:  A script that fetches cracked passwords from the following site:
#               https://www.nitrxgen.net/md5db/
#
#
# --TODO--
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

URL="https://www.nitrxgen.net/md5db/"
DICT_DIR=~/dictionaries
DICT=$DICT_DIR/CUSTOM_md5db.txt


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
cat $OUT_HTML | grep -F '<div class="ellipsis"' | cut -d'>' -f5 | cut -d'<' -f1 >> $DICT

sort -u $DICT -o $DICT

rm -f $OUT_HTML $OUT_CSV

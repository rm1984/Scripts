#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        pwd_sucker_crackpot.sh
#
# Description:  A script that fetches cracked passwords from the following site:
#               http://cracker.offensive-security.com/index.php
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

URL="http://cracker.offensive-security.com/index.php"
DICT_DIR=~/dictionaries
DICT=$DICT_DIR/CUSTOM_crackpot.txt


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
TMP=/tmp/.crackpot.txt
SDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

wget -O $OUT_HTML $URL > /dev/null 2>&1
$SDIR/htmltable2csv.py $OUT_HTML > /dev/null 2>&1

OUT_CSV="$(echo $OUT_HTML | sed -e 's/html/csv/g')"

grep '^"[0-9]' $OUT_CSV | cut -d',' -f4 | sed 's/^"\(.*\)"$/\1/' | grep -v 'NOT-FOUND' > $TMP

cat $TMP >> $DICT
sort -u $DICT -o $DICT

rm -f $OUT_HTML $OUT_CSV $TMP

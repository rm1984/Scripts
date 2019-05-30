#!/usr/bin/env bash

[[ $DEBUG -ne 0 ]] && set -x

URL="https://www.nitrxgen.net/md5db/"
DICT_DIR=~/dictionaries
DICT=$DICT_DIR/CUSTOM_md5db.txt
OUT_HTML=$(echo /tmp/.rnd-${RANDOM}.html)

wget $URL -O $OUT_HTML
cat $OUT_HTML | grep -F '<div class="ellipsis"' | cut -d'>' -f5 | cut -d'<' -f1 >> $DICT

sort -u $DICT -o $DICT

rm -f $OUT_HTML $OUT_CSV

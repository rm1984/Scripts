#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        dict_split_n_sort.sh
#
# Description:  This script takes a dictionary text file as input, reads all the
#               passwords in it and saves each password in a dedicated text file
#               depending on its first character. For example, all passwords
#               beginning with "a" will be saved in "a.txt", all passwords
#               beginning with "B" will be saved in "B.txt", and so on.
#
# Usage:        ./dict_split_n_sort.sh <DICTIONARY.txt>
#
#
# --TODO--
# - improve and optimize code
# - better checks for command line parameters, files and strings
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

SORTED_OUT_DIR=~/DICTIONARIES/SORTED


# MAIN -------------------------------------------------------------------------

if [[ "$#" -eq 0 ]] ; then
    echo "Usage: dict_split_n_sort.sh <DICTIONARY.txt>"

    exit 1
fi

export LC_ALL=C

INFILE=$1

DICT=$(readlink -f $INFILE)
PWDS=$(wc -l $DICT | awk '{ print $1 }')
SIZE=$(du -sh $DICT | awk '{ print $1 }')

mkdir -p $SORTED_OUT_DIR

echo "Dictionary:  $DICT"
echo "Passwords:   $PWDS"
echo "Size:        $SIZE"
echo "Output dir:  $SORTED_OUT_DIR"
echo
echo "Splitting started at:  $(date)"

#DIVD=$(echo $(($PWDS/20)))

while read line ; do
    FIRSTCHAR=${line:0:1}
    OUTFILE=${FIRSTCHAR}.txt

    if [[ -z "${FIRSTCHAR//[a-zA-Z0-9]}" && ! -z "${FIRSTCHAR}" ]] ; then
        OUTFILE=$SORTED_OUT_DIR/$FIRSTCHAR.txt
    else
        OUTFILE=$SORTED_OUT_DIR/_others_.txt
    fi

    echo -n "${line}" >> $OUTFILE
    echo >> $OUTFILE
done < $DICT

echo "."
echo "Splitting finished at: $(date)"
echo
echo "Sorting started at:    $(date)"

for CHAR_DICT in $(ls -1 $SORTED_OUT_DIR/*.txt) ; do
    sort -i -u $CHAR_DICT -o $CHAR_DICT

    echo -n "."
done

echo "."
echo "Sorting finished at:   $(date)"

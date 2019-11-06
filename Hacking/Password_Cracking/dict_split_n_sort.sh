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
#               Password beginning with uncommon characters will be saved in a
#               file named "_others_.txt".
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

if [[ ! -f "$INFILE" ]]; then
    echo "Dictionary file \"$INFILE\" doesn't exist!"

    exit 1
fi

DICT=$(readlink -f $INFILE)
PWDS=$(wc -l $DICT | awk '{ print $1 }')
SIZE=$(du -sh $DICT | awk '{ print $1 }')

mkdir -p $SORTED_OUT_DIR

echo "Dictionary:  $DICT"
echo "Passwords:   $PWDS"
echo "Size:        $SIZE"
echo "Output dir:  $SORTED_OUT_DIR"
echo
echo "Splitting started at:   $(date)"

C=0

while read LINE ; do
    C=$((C+1))
    FIRSTCHAR=${LINE:0:1}
    OUTFILE=${FIRSTCHAR}.txt

    if [[ -z "${FIRSTCHAR//[a-zA-Z0-9]}" && ! -z "${FIRSTCHAR}" ]] ; then
        OUTFILE=$SORTED_OUT_DIR/$FIRSTCHAR.txt
    else
        OUTFILE=$SORTED_OUT_DIR/_others_.txt
    fi

    echo -n "${LINE}" >> $OUTFILE
    echo >> $OUTFILE

    PERC=$((100*C/PWDS))

    echo -ne "(${PERC}%)\r"
done < $DICT

echo "Splitting finished at:  $(date)"
echo
echo "Sorting started at:     $(date)"

TOT=0

for CHAR_DICT in $(ls -1 $SORTED_OUT_DIR/*.txt) ; do
#    sort -i -u $CHAR_DICT -o $CHAR_DICT
    sort -u $CHAR_DICT -o $CHAR_DICT

    N=$(wc -l $CHAR_DICT | awk '{ print $1 }')
    TOT=$((TOT+N))

    echo -ne "(${CHAR_DICT}%)\r"
done

echo "Sorting finished at:    $(date)"
echo
echo "Total passwords: $TOT"

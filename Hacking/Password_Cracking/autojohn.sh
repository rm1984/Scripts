#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        autojohn.sh
#
# Description:  A script that is meant to simplify and automate the usage of the
#               powerful JohnTheRipper password cracking tool.
#               At the moment, it is solely intended for dictionary attacks.
#
# Usage:        ./autojohn.sh --info
#               ./autojohn.sh <HASHES_FILE>
#               ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME>
#
#
# --TODO--
# - various checks (files, dirs, ...)
# - detect number of cores (for Linux and FreeBSD)
# - improve and optimize code
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DICT_DIR=~/dictionariescd      # each wordlist in this directory MUST be a ".txt" file
POTS_DIR=~/.john            # here you will find cracked passwords
CORES=4                     # number of parallel processes/tasks


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}

usage() {
    echo "Usage:"
    echo "  - Show information about dictionaries:"
    echo "    ./autojohn.sh --info"
    echo "  - List detected hash formats for file <HASHES_FILE>:"
    echo "    ./autojohn.sh <HASHES_FILE>"
    echo "  - Start cracking hashes with dictionary attack:"
    echo "    ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME>"
}

logo() {
    echo "                        "
    echo " /\   _|_ _   | _ |_ ._ "
    echo "/--\|_||_(_)\_|(_)| || |"
    echo "                        "
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"john"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

if [[ ! -d "$DICT_DIR" ]] ; then
    echo "Error! Dictionaries directory not found: $DICT_DIR"

    exit 1
fi

if [[ ! -d "$POTS_DIR" ]] ; then
    echo "Error! Pots directory not found: $POTS_DIR"

    exit 1
fi


# MAIN -------------------------------------------------------------------------

if [[ "$#" -ne 1 && "$#" -ne 3 ]] ; then
    usage

    exit 1
else
    FILE=$1

    if [[ "$#" -eq 1 ]] ; then
        logo

        if [[ "$FILE" == "--help" || "$FILE" == "-h" ]] ; then
            usage

            exit 0
        elif [[ "$FILE" == "--info" ]] ; then
            DICT_NUM=$(ls -1 $DICT_DIR/*txt | wc -l)
            DICT_SIZ=$(du -ch $DICT_DIR/*txt | tail -1 | awk '{ print $1 }')

            echo "[+] Dictionaries directory:  $DICT_DIR"
            echo "[+] Number of dictionaries:  $DICT_NUM"
            echo "[+] Total dictionaries size: $DICT_SIZ"
            echo

            exit 0
        fi

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"

            exit 1
        fi

        echo "Detected hash formats:"
        echo

        john --list=unkonwn $FILE 2>&1 | grep -F -- '--format=' | grep -v '\$' | cut -d'=' -f2 | cut -d'"' -f1 | sort | awk '{ $2 = $1 ; $1 = "-" ; print $0 }'

        echo
        echo "Now, to start cracking, run:"
        echo "./autojohn.sh $FILE <FORMAT> <SESSION_NAME>"

        exit 0
    elif [[ "$#" -eq 3 ]] ; then
        logo

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"

            exit 1
        fi

        FORMAT=$2
        SESSION=$3
        STATUS=$(john --show --pot=$POTS_DIR/$SESSION.pot --format=$FORMAT $FILE | grep -F cracked)
        C=$(echo $STATUS | grep -c -F ', 0 left')

        if [[ $C -eq 1 ]] ; then
	        echo "All passwords already found! Exiting..."
	        echo

	        exit 0
        fi

        N=$(cat $FILE | wc -l | tr -d ' ')

        echo "[+] Session name: $SESSION"
        echo "[+] Total hashes: $N"
        echo "[+] Hash format:  $FORMAT"
        echo

        echo "[START] $(date)"
        echo

        for DICT in $(ls -1Sr $DICT_DIR/*.txt) ; do
	        echo "[>] $DICT"

	        john --wordlist=$DICT --format=$FORMAT --nolog --fork=$CORES --session=$SESSION --pot=$POTS_DIR/$SESSION.pot $FILE >> $POTS_DIR/$SESSION.progress 2>&1

	        STATUS=$(john --show --pot=$POTS_DIR/$SESSION.pot --format=$FORMAT $FILE | grep -F cracked)

	        echo $STATUS

	        C=$(echo $STATUS | grep -c -F ', 0 left')

	        if [[ $C -eq 1 ]] ; then
		        echo
		        echo "Congratulation! All passwords found!"
		        echo
		        echo "[END] $(date)"
                echo
                echo "Found passwords (saved in $POTS_DIR/$SESSION.pot):"
                cat $POTS_DIR/$SESSION.pot | cut -d':' -f2 | sort -u

		        exit 0
	        fi
        done

        echo
        echo "[END] $(date)"
        echo
        echo "Found passwords (saved in $POTS_DIR/$SESSION.pot):"
        cat $POTS_DIR/$SESSION.pot | cut -d':' -f2 | sort -u
    fi
fi

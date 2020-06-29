#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:         autojohn.sh
#
# Description:  A script that is meant to simplify and automate the usage of the
#               powerful JohnTheRipper password cracking tool.
#               At the moment, it is solely intended for dictionary attacks.
#
# Usage:        ./autojohn.sh --help|-h
#               ./autojohn.sh --info
#               ./autojohn.sh <HASHES_FILE>
#               ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME> [<RULE>]
#               ./autojohn.sh --sessions
#               ./autojohn.sh --show <SESSION_NAME>
#               ./autojohn.sh --rules
#               ./autojohn.sh --polish
#
#
# --TODO--
# - improve and optimize code
# - better checks for command line parameters
# - implement simple bruteforce:
#     john test.txt --format=Raw-MD5 -1=?l -mask=?1?1?1?1?1?1?1 --fork=4
#     ./autojohn.sh --bruteforce --min <MIN_LENGTH> --max 8 --mask <DLUA> <HASHES_FILE> <FORMAT> <SESSION_NAME>
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DICT_DIR=~/DICTIONARIES     # each wordlist in this directory *MUST* be a ".txt" file
POTS_DIR=~/.autojohn            # here you will find the cracked passwords for each session


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}

logo() {
    echo "                        "
    echo " /\   _|_ _   | _ |_ ._ "
    echo "/--\|_||_(_)\_|(_)| || |"
    echo "                        "
}

usage() {
    echo "Usage:"
    echo
    echo "  - Show this help:"
    echo "    ./autojohn.sh [--help|-h]"
    echo
    echo "  - Show information about dictionaries:"
    echo "    ./autojohn.sh --info"
    echo
    echo "  - List detected hash formats for file <HASHES_FILE>:"
    echo "    ./autojohn.sh <HASHES_FILE>"
    echo
    echo "  - Start cracking hashes with dictionary attack:"
    echo "    ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME> [<RULE>]"
    echo "    (warning: with rules like \"EXTRA\" or \"ALL\" it may take *ages*)"
    echo
    echo "  - Show sessions (both [F]inished and [R]unning):"
    echo "    ./autojohn.sh --sessions"
    echo
    echo "  - Show currently found passwords in a session:"
    echo "    ./autojohn.sh --show <SESSION_NAME>"
    echo
    echo "  - List available (optional) rules:"
    echo "    ./autojohn.sh --rules"
    echo
    echo "  - Clean all the dictionaries by removing non-printable characters"
    echo "    and DOS newlines (CR-LF) and finally by (unique-)sorting them:"
    echo "    ./autojohn.sh --polish"
    echo "    (warning: depending on the size of the dictionaries, it may take a"
    echo "     very long time and require a lot of temporary disk space)"
    echo
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"awk"
"basename"
"dos2unix"
"john"
"shasum"
"tr"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

if [[ ! -d "$DICT_DIR" ]] ; then
    echo "Error! Dictionaries directory not found: $DICT_DIR"

    exit 1
else
    DICT_NUM=$(ls -1q $DICT_DIR/*.txt 2> /dev/null | wc -l)

    if [[ "$DICT_NUM" -eq 0 ]] ; then
        echo "Error! No *.txt dictionaries found!"

        exit 1
    fi
fi

if [[ ! -d "$POTS_DIR" ]] ; then
    #echo "Error! Pots directory not found: $POTS_DIR"
    #exit 1
    mkdir -p "$POTS_DIR"
fi


# MAIN -------------------------------------------------------------------------

if [[ "$#" -eq 0 || ! "$#" -le 4 ]] ; then
    usage

    exit 1
else
    PARAM=$1

    if [[ $OS == "Linux" ]] ; then
        DU_A_PARAM='--apparent-size'
    elif [[ $OS == "FreeBSD" ]] ; then
        DU_A_PARAM='-A'
    else
        DU_A_PARAM=''
    fi

    if [[ "$#" -eq 1 ]] ; then
        logo

        if [[ "$PARAM" == "--help" || "$PARAM" == "-h" ]] ; then
            usage

            exit 0
        elif [[ "$PARAM" == "--info" ]] ; then
            DICT_NUM=$(ls -1 $DICT_DIR/*txt | wc -l | awk '{ print $1 }')
            DICT_SIZ=$(du -ch $DU_A_PARAM $DICT_DIR/*txt | tail -1 | awk '{ print $1 }')

            echo "[+] Dictionaries directory:   $DICT_DIR"
            echo "[+] Number of dictionaries:   $DICT_NUM"
            echo "[+] Total dictionaries size:  $DICT_SIZ"
            echo

            exit 0
        elif [[ "$PARAM" == "--sessions" ]] ; then
            N=$(ls -1 $POTS_DIR/*.pot 2> /dev/null | wc -l | awk '{ print $1 }')

            if [[ "$N" -eq 0 ]] ; then
                echo "No sessions found (pots directory seems empty)."
            else
                for SESSION in $(ls -1 $POTS_DIR/*.pot | sed -r 's/.*\/(.*).pot.*/\1/') ; do
                    if [[ -f "$POTS_DIR/$SESSION.progress" ]] ; then
                        ps auxwww | grep john | grep -- "--session=$SESSION" > /dev/null

                        if [[ $? -ne 0 ]] ; then
                            echo "[R] $SESSION (dead?)"
                        else
                            echo "[R] $SESSION"
                        fi
                    else
                        echo "[F] $SESSION"
                    fi
                done
            fi

            echo

            exit 0
        elif [[ "$PARAM" == "--rules" ]] ; then
            john --list=rules | sort -h

            echo

            exit 0
        elif [[ "$PARAM" == "--polish" ]] ; then
            export LC_CTYPE=C
            export LC_ALL=C

            MEMORY_USAGE="50%" # maximum memory usage for sort command
            CSV=$POTS_DIR/polished_dicts.csv

            echo "FILENAME;START_TIME;END_TIME;OLD_SIZE;NEW_SIZE" > $CSV

            for DICT in $(ls -1Sr $DICT_DIR/*.txt) ; do
                BNDICT=$(basename $DICT)

                echo "[>] $BNDICT"

                STIME=$(date)
                OLDSIZE=$(du -sh $DU_A_PARAM $DICT | awk '{ print $1 }')

                echo "    Started at:    $STIME"
                echo "    Current size:  $OLDSIZE"

                NEWDICT="${DICT}.NEW"

                tr -dc '[:print:]\n\r' < $DICT > $NEWDICT
                sleep 1
                dos2unix $NEWDICT > /dev/null 2>&1
                sleep 1
                sort -S $MEMORY_USAGE -u $NEWDICT > $DICT 2>&1
                sleep 1
                rm $NEWDICT

                NEWSIZE=$(du -sh $DU_A_PARAM $DICT | awk '{ print $1 }')
                ETIME=$(date)

                echo "    New size:      $NEWSIZE"
                echo "    Finished at:   $ETIME"
                echo "$BNDICT;$STIME;$ETIME;$OLDSIZE;$NEWSIZE" >> $CSV
                echo
            done

            echo "Results can also be found in the following CSV file:"
            echo "$CSV"
            echo

            exit 0
        fi

        if [[ $PARAM == --* ]] ; then
            echo "Wrong parameter: $PARAM"
            echo

            exit 1
        fi

        FILE="$PARAM"

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"
            echo

            exit 1
        fi

        readarray -t FORMATS < <(
        {
            john --list=unknown $FILE 2>&1 | awk -F\" '{ print $2 }' | sed -e 's/--format=//g' | sort -u | sed '/^$/d'
            john --list=unknown $FILE 2>&1 | grep -F 'Loaded' | cut -d'(' -f2 | cut -d' ' -f1 | tr -d ','
        })

        if [[ ${#FORMATS[@]} -eq 0 ]] ; then
            echo "No valid hash formats detected!!! :-("
            echo
        else
            echo "Detected hash formats:"
            echo

            FORMATS=($(echo ${FORMATS[@]} | tr ' ' '\n' | sort -u))

            for F in "${FORMATS[@]}" ; do
                echo "- $F"
            done

            echo
            echo "Now, to start cracking, run:"
            echo "./autojohn.sh $FILE <FORMAT> <SESSION_NAME> [<RULE>]"
            echo
        fi

        exit 0
    elif [[ "$#" -eq 2 ]] ; then
        logo

        if [[ "$1" == "--show" ]] ; then
            SESSION=$2

            if [[ $SESSION == --* ]] ; then
                echo "Wrong value for <SESSION_NAME>: $SESSION"
                echo

                exit 1
            fi

            CSV_FILE=$POTS_DIR/$SESSION.csv

            if [[ -f "$CSV_FILE" ]] && [[ -s "$CSV_FILE" ]] ; then
                echo "Found passwords in session \"$SESSION\"":
                echo "---------------"

                cat $CSV_FILE

                echo
            else
                echo "No passwords found (at the moment!) for session \"$SESSION\"."
                echo
            fi
        fi

        exit 0
    elif [[ "$#" -eq 3 || "$#" -eq 4 ]] ; then
        logo

        FILE=$1
        FORMAT=$2
        SESSION=$3
        RULE=""

        if [[ "$#" -eq 4 ]] ; then
            RULE=$4

            if [[ $(john --list=rules | grep -c -i -w $RULE) -eq 0 ]] ; then
                echo "Error! Rule does not exist: $RULE"
                echo

                exit 1
            fi
        fi

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"
            echo

            exit 1
        fi

        if [[ $FORMAT == --* ]] ; then
            echo "Wrong value for <FORMAT>: $FORMAT"
            echo

            exit 1
        fi

        if [[ $SESSION == --* ]] ; then
            echo "Wrong value for <SESSION_NAME>: $SESSION"
            echo

            exit 1
        fi

        POT_FILE=$POTS_DIR/$SESSION.pot
        PWD_FILE=$POTS_DIR/$SESSION.csv
        PROGRESS_FILE=$POTS_DIR/$SESSION.progress
        STATUS=$(john --show --pot=$POT_FILE --format=$FORMAT $FILE | grep -F cracked)
        C=$(echo $STATUS | grep -c -F ', 0 left')

        if [[ $C -eq 1 ]] ; then
            echo "All passwords already found! Exiting..."
            echo

            exit 0
        fi

        OS=$(uname -s)

        if [[ $OS == "Linux" ]] ; then
            CORES=$(grep -c ^processor /proc/cpuinfo)
        elif [[ $OS == "FreeBSD" ]] ; then
            CORES=$(sysctl -n hw.ncpu)
        else
            CORES=1
        fi

        N=$(cat $FILE | wc -l | tr -d ' ')
        SHA=$(shasum $FILE | awk '{ print $1 }')
        BFILE=$(basename $FILE)

        cp $FILE $POTS_DIR/"${SESSION}_${BFILE}_${SHA}"

        echo "[+] Hashes file:   $(readlink -f $FILE)"
        echo "[+] Session name:  $SESSION"
        echo "[+] Total hashes:  $N"
        echo "[+] Hash format:   $FORMAT"

        if [[ -z "$RULE" ]] ; then
            echo "[+] Rule:          *DEFAULT*"
        else
            echo "[+] Rule:          $RULE"
        fi

        echo "[+] # of cores:    $CORES"
        echo
        echo "===> Started at:  $(date) <==="
        echo

        for DICT in $(ls -1Sr $DICT_DIR/*.txt) ; do
            BNDICT=$(basename $DICT)

            echo "[>] $BNDICT"

            if [[ -z "$RULE" ]] ; then
                john --wordlist=$DICT --format=$FORMAT --nolog --fork=$CORES --session=$SESSION --pot=$POT_FILE $FILE >> $PROGRESS_FILE 2>&1
            else
                john --wordlist=$DICT --format=$FORMAT --rules=$RULE --nolog --fork=$CORES --session=$SESSION --pot=$POT_FILE $FILE >> $PROGRESS_FILE 2>&1
            fi

            STATUS=$(john --show --pot=$POT_FILE --format=$FORMAT $FILE | grep -F cracked)
            echo $STATUS
            C=$(echo $STATUS | grep -c -F ', 0 left')

            if [[ $C -eq 1 ]] ; then
                echo
                echo "************************"
                echo "*   Congratulations!   *"
                echo "* All passwords found! *"
                echo "************************"

                break
            fi
        done

        echo
        echo "===> Finished at: $(date) <==="
        echo
        echo "Found passwords (saved in $PWD_FILE):"
        echo "---------------"

        john --show --pot=$POT_FILE --format=$FORMAT $FILE | grep -F ':' | tee $PWD_FILE

        if [[ $? -ne 0 ]] ; then
            echo "None :-("
        fi

        if [[ -f $PROGRESS_FILE ]] ; then
            rm -f $PROGRESS_FILE
        fi

        echo

        exit 0
    fi
fi

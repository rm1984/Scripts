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
#               ./autojohn.sh <HASHES_FILE>
#               ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME> [<RULE>]
#               ./autojohn.sh --info
#               ./autojohn.sh --sessions
#               ./autojohn.sh --show <SESSION_NAME>
#               ./autojohn.sh --rules
#               ./autojohn.sh --polish
#               ./autojohn.sh --clean
#
#
# --TODO--
# - improve and optimize code
# - implement simple bruteforce:
#     john test.txt --format=Raw-MD5 -1=?l -mask=?1?1?1?1?1?1?1 --fork=4
#     ./autojohn.sh --bruteforce --min <MIN_LENGTH> --max 8 --mask <DLUA> <HASHES_FILE> <FORMAT> <SESSION_NAME>
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DICT_DIR=~/DICTIONARIES     # each dictionary/wordlist in this directory *MUST* be a plain text ".txt" file
POTS_DIR=~/.autojohn        # here you will find the cracked passwords from each session


# OTHER VARIABLES (don't touch them!) ------------------------------------------

OS=$(uname -s)

if [[ $OS == "Linux" ]] ; then
    DU_A_PARAM='--apparent-size'
    CORES=$(grep -c ^processor /proc/cpuinfo)
elif [[ $OS == "FreeBSD" ]] ; then
    DU_A_PARAM='-A'
    CORES=$(sysctl -n hw.ncpu)
else
    DU_A_PARAM=''
    CORES=1
fi


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" > /dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
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
    echo "    ./autojohn.sh [--help|-h]"
    echo "    show this help"
    echo
    echo "    ./autojohn.sh --info"
    echo "    show some information about dictionaries"
    echo
    echo "    ./autojohn.sh <HASHES_FILE>"
    echo "    list detected hash formats for file <HASHES_FILE>"
    echo
    echo "    ./autojohn.sh <HASHES_FILE> <FORMAT> <SESSION_NAME> [<RULE>]"
    echo "    start cracking hashes with dictionary attack"
    echo "    (warning: with rules like \"EXTRA\" or \"ALL\" it may take *ages*)"
    echo
    echo "    ./autojohn.sh --sessions"
    echo "    show sessions (both [F]inished and [R]unning)"
    echo
    echo "    ./autojohn.sh --show <SESSION_NAME>"
    echo "    show currently found passwords in session <SESSION_NAME>"
    echo
    echo "    ./autojohn.sh --rules"
    echo "    list available (optional) JohnTheRipper rules"
    echo
    echo "    ./autojohn.sh --polish"
    echo "    clean all the dictionaries by removing non-printable characters"
    echo "    and DOS newlines (CR-LF) and finally by (unique-)sorting them"
    echo "    (warning: depending on the size of the dictionaries, it may take"
    echo "    a very long time and require a lot of temporary disk space)"
    echo
    echo "    ./autojohn.sh --clean"
    echo "    delete all files in pots directory (except CSV with passwords and"
    echo "    stats) and the *.rec leftovers"
    echo

    exit 0
}

info() {
    DICT_NUM=$(find $DICT_DIR/*txt | wc -l | awk '{ print $1 }')
    DICT_SIZ=$(du -ch "$DU_A_PARAM" $DICT_DIR/*txt | tail -1 | awk '{ print $1 }')

    echo "[+] Dictionaries directory:   $DICT_DIR"
    echo "[+] Number of dictionaries:   $DICT_NUM"
    echo "[+] Total dictionaries size:  $DICT_SIZ"
    echo "[+] Pots directory:           $POTS_DIR"
    echo

    exit 0
}

sessions() {
    N=$(find $POTS_DIR/*.pot 2> /dev/null | wc -l | awk '{ print $1 }')

    if [[ "$N" -eq 0 ]] ; then
        echo "No sessions found (pots directory seems empty)."
    else
        for SESSION in $(find $POTS_DIR/*.pot | sed -r 's/.*\/(.*).pot.*/\1/') ; do
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
}

rules () {
    john --list=rules | sort -h

    echo

    exit 0
}

polish() {
    export LC_CTYPE=C
    export LC_ALL=C

    MEMORY_USAGE="50%" # maximum memory usage for "sort" command (think before changing it!)
    CSV=$POTS_DIR/polished_dicts.csv

    if [[ ! -w $CSV ]] ; then
        echo "FILENAME;START_TIME;END_TIME;OLD_SIZE;NEW_SIZE" > $CSV
    fi

    for DICT in $(ls -1Sr $DICT_DIR/*.txt) ; do
        BNDICT=$(basename "$DICT")

        echo "[>] $BNDICT"

        STIME=$(date)
        OLDSIZE=$(du -h "$DU_A_PARAM" "$DICT" | awk '{ print $1 }')

        echo "    Started at:    $STIME"
        echo "    Current size:  $OLDSIZE"

        NEWDICT="${DICT}.NEW"

        tr -dc '[:print:]\n\r' < "$DICT" > "$NEWDICT"
        sleep 1
        dos2unix "$NEWDICT" > /dev/null 2>&1
        sleep 1
        sort -S "$MEMORY_USAGE" -u "$NEWDICT" > "$DICT" 2>&1
        sleep 1
        rm "$NEWDICT"

        NEWSIZE=$(du -h "$DU_A_PARAM" "$DICT" | awk '{ print $1 }')
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
}

clean() {
	SCRIPT_DIR="$( cd "$(dirname "$0")" > /dev/null 2>&1 ; pwd -P )"
	rm -f $SCRIPT_DIR/*.rec

    find $POTS_DIR -type f -not -name 'polished_dicts.csv' -delete

    if [[ $? -eq 0 ]] ; then
        echo "Pots directory was cleaned up."
        echo

        exit 0
    else
        echo "Error! Cannot clean pots directory: $POTS_DIR"
        echo

        exit 1
    fi
}

show() {
    SESSION=$1

    PRG_FILE=$POTS_DIR/$SESSION.progress
    CSV_FILE=$POTS_DIR/$SESSION.csv

    if [[ -f "$PRG_FILE" ]] && [[ -s "$PRG_FILE" ]] ; then
        echo "Found passwords in session \"$SESSION\"":
        echo

        # not so elegant but it works... need something better btw!
        grep -e '(.*)' "$PRG_FILE" | grep -v 'DONE (' | grep -v '^Loaded' | grep -v '^Node numbers' | sort -u

        echo
    elif [[ -f "$CSV_FILE" ]] && [[ -s "$CSV_FILE" ]] ; then
        echo "Found passwords in session \"$SESSION\"":
        echo

        sort -u "$CSV_FILE"

        echo
    else
        echo "No passwords found (at the moment!) for session \"$SESSION\"."
        echo
    fi
}

crack() {
    PARAMS_COUNT=$(echo "$PARAMS" | wc -w)
    PARAMS_ARRAY=("$PARAMS")

    if [[ "$PARAMS_COUNT" -eq 1 ]] ; then
        FILE="${PARAMS_ARRAY[0]}"

        if [[ ! -f "$FILE" ]] ; then
            echo "Error! Hashes file not found: $FILE"
            echo

            exit 1
        fi

        readarray -t FORMATS < <(
        {
            john --list=unknown "$FILE" 2>&1 | awk -F\" '{ print $2 }' | sed -e 's/--format=//g' | sort -u | sed '/^$/d'
            john --list=unknown "$FILE" 2>&1 | grep -F 'Loaded' | cut -d'(' -f2 | cut -d' ' -f1 | tr -d ','
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
    elif [[ "$PARAMS_COUNT" -eq 3 || "$PARAMS_COUNT" -eq 4 ]] ; then
        FILE="${PARAMS_ARRAY[0]}"
        FORMAT="${PARAMS_ARRAY[1]}"
        SESSION="${PARAMS_ARRAY[2]}"
        RULE=""

        if [[ "$PARAMS_COUNT" -eq 4 ]] ; then
            RULE="${PARAMS_ARRAY[3]}"

            if [[ $(john --list=rules | grep -c -i -w "$RULE") -eq 0 ]] ; then
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
        STATUS=$(john --show --pot="$POT_FILE" --format="$FORMAT" "$FILE" | grep -F cracked)
        C=$(echo "$STATUS" | grep -c -F ', 0 left')

        if [[ $C -eq 1 ]] ; then
            echo "All passwords already found! Exiting..."
            echo

            exit 0
        fi

        N=$(wc -l "$FILE" | awk '{ print $1 }')
        SHA=$(shasum "$FILE" | awk '{ print $1 }')
        BFILE=$(basename "$FILE")

        cp "$FILE" $POTS_DIR/"${SESSION}_${BFILE}_${SHA}"

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
            BNDICT=$(basename "$DICT")

            echo "[>] $BNDICT"

            if [[ -z "$RULE" ]] ; then
                john --wordlist="$DICT" --format="$FORMAT" --nolog --fork="$CORES" --session="$SESSION" --pot="$POT_FILE" "$FILE" >> "$PROGRESS_FILE" 2>&1
            else
                john --wordlist="$DICT" --format="$FORMAT" --nolog --fork="$CORES" --session="$SESSION" --pot="$POT_FILE" --rules="$RULE" "$FILE" >> "$PROGRESS_FILE" 2>&1
            fi

            STATUS=$(john --show --pot="$POT_FILE" --format="$FORMAT" "$FILE" | grep -F cracked)
            echo "$STATUS"
            C=$(echo "$STATUS" | grep -c -F ', 0 left')

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
        echo

        john --show --pot="$POT_FILE" --format="$FORMAT" "$FILE" | grep -F ':' | sort -u | tee "$PWD_FILE"

        if [[ $? -ne 0 ]] ; then
            echo "None :-("
        fi

        if [[ -f "$PROGRESS_FILE" ]] ; then
            rm -f "$PROGRESS_FILE"
        fi

        echo

        exit 0
    fi
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
    command_exists "$CMD"
done

if [[ ! -d "$DICT_DIR" ]] ; then
    echo "Error! Dictionaries directory not found: $DICT_DIR"

    exit 1
else
    DICT_NUM=$(find $DICT_DIR/*.txt 2> /dev/null | wc -l)

    if [[ "$DICT_NUM" -eq 0 ]] ; then
        echo "Error! No *.txt dictionaries found."

        exit 1
    fi
fi

if [[ ! -d "$POTS_DIR" ]] ; then
    mkdir -p "$POTS_DIR" 2> /dev/null

    if [[ "$?" -ne 0 ]] ; then
        echo "Error! Cannot create pots directory: $POTS_DIR"

        exit 1
    fi
fi


# MAIN -------------------------------------------------------------------------

logo

if [[ "$#" -eq 0 ]] ; then
    usage
fi

PARAMS=""

while (( "$#" )) ; do
  case "$1" in
    -h|--help)
        usage
        shift
        ;;
    --clean)
        clean
        shift
        ;;
    --info)
        info
        shift
        ;;
    --polish)
        polish
        shift
        ;;
    --rules)
        rules
        shift
        ;;
    --sessions)
        sessions
        shift
        ;;
    --show)
        if [ -n "$2" ] && [ "${2:0:1}" != "-" ] ; then
            show "$2"
            shift 2
        else
            echo "Error! Argument for $1 is missing." >&2
            echo

            exit 1
        fi
        ;;
    -*|--*=) # unsupported flags
        echo "Error! Unsupported flag: $1" >&2
        echo

        exit 1
        ;;
    *) # preserve positional arguments
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
done

eval set -- "$PARAMS"

crack "$PARAMS"
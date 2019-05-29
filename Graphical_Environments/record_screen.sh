#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        record_screen.sh [-f FRAMES_PER_SECOND] [-o OUTPUT_FILE]
#
# Description:  A script that records a screencast and saves it to a file.
#               Press CTRL+C to stop recording.
#
# Usage:        ./record_screen.sh [-f FRAMES_PER_SECOND] [-o OUTPUT_FILE]
#
#
# --TODO--
# - ???
#
#
################################################################################


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}

usage() {
    echo "Usage: $0 [-f FRAMES_PER_SECOND] [-o OUTPUT_FILE]" 1>&2 ; exit 1 ;
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"ffmpeg"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

while getopts ":f:o:" OPTS ; do
    case "${OPTS}" in
        f)
            FRAMES_PER_SECOND=${OPTARG}
            ;;
        o)
            OUTPUT_FILE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z "${FRAMES_PER_SECOND}" || -z "${OUTPUT_FILE}" ]] ; then
    usage
fi


# MAIN -------------------------------------------------------------------------

if [[ -z ${DISPLAY} ]] ; then
    echo "DISPLAY variable is not set. Please make sure you are running in a graphical environment."

    exit 1
fi

ffmpeg -f x11grab -s wxga -r ${FRAMES_PER_SECOND} -i ${DISPLAY} -qscale 0 ${OUTPUT_FILE}


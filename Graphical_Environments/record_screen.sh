#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        record_screen.sh
#
# Description:  A script that records a screencast and saves it to a file.
#               Press CTRL+C to stop recording.
#
# Usage:        record_screen.sh [-o OUTPUT_FILE] [-r FRAMES_PER_SECOND]
#
#
# --TODO--
# - Handle parameters from command line
# - Check DISPLAY validity
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

OUTPUT_FILE="/tmp/out.mpg"
FRAMES_PER_SECOND=25


# FUNCTIONS --------------------------------------------------------------------

command_exists () {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" >&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"ffmpeg"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

ffmpeg -f x11grab -s wxga -r ${FRAMES_PER_SECOND} -i ${DISPLAY} -qscale 0 ${OUTPUT_FILE}

#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        share_dir_via_rdp.sh
#
# Description:  A script that maps and shares a local directory to a remote Windows
#               machine via RDP.
#
# Usage:        /share_dir_via_rdp.sh <local_dir> <rdp_server> [<screen_resolution>]
#
#
# --TODO--
# - Handle parameters from command line
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

LOCAL_DIR=$1
RDP_SERVER=$2
SCRN_RES=$3
THIS=$(basename "$0")


# FUNCTIONS --------------------------------------------------------------------

check_cmd () {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" >&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"rdesktop"
);

for CMD in ${CMDS[@]} ; do
    check_cmd $CMD
done


# MAIN -------------------------------------------------------------------------

if (( $# < 2 )) ; then
    echo "Usage:    $THIS <local_dir> <rdp_server> [<screen_resolution>]"
    echo
    echo "          <local_dir>     -    Local directory to share on remote machine"
    echo "          <rdp_server>    -    Remote RDP target machine"

    exit 1
fi

rdesktop -r disk:share="${LOCAL_DIR}" -g "${SCRN_RES}" "${RDP_SERVER}"

#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        magnet2torrent.sh
#
# Description:  A script that gets a Magnet link as input and returns a valid
#               .torrent file as output. You must be able to connect to the
#               BitTorrent network to use this tool.
#
# Usage:        ./magnet2torrent.sh '<magnet_uri>' <output_dir>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

MAGNET=$1
OUTDIR=$2


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"aria2c"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done

if [[ "$#" -ne 2 ]] ; then
    echo "Usage: ./magnet2torrent.sh '<magnet_uri>' <output_dir>"

    exit 1
fi


# MAIN -------------------------------------------------------------------------

if [[ -d ${OUTDIR} ]] ; then
    mkdir -p ${OUTDIR}
fi

aria2c -d ${OUTDIR} --bt-metadata-only=true --bt-save-metadata=true --listen-port=6881 "${MAGNET}"

#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        image_orientation.sh <DIRECTORY_WITH_IMAGES>
#
# Description:  A script that, for every image in a folder, prints its pixel
#               resolution and its orientation (portrait, landscape or squared).
#               The script "aspectpad" by Fred Weinhaus is required.
#
# Usage:        ./image_orientation.sh <DIRECTORY_WITH_IMAGES>
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


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"identify"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ "$#" -eq 0 ]] ; then
    echo "./image_orientation.sh <DIRECTORY_WITH_IMAGES>"

    exit 1
fi

DIR=$1

if [[ ! -d "$DIR" ]] ; then
    echo "Error! Directory with images not found: $DIR"

    exit 1
fi

SCR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
OLD_DIR=$(pwd)

if [[ ! -x "$SCR_DIR/aspectpad" ]] ; then
    echo "Error! Script \"aspectpad\" not found (it must be in the same directory of this script)."

    exit 1
fi

cd $1
for IMG in $(ls -1 *jpg *JPG *png *PNG 2> /dev/null) ; do
    SIZE=$(identify -format '%w %h' $IMG | sed -e 's/\ /x/g')
    W=$(echo $SIZE | cut -d'x' -f1)
    H=$(echo $SIZE | cut -d'x' -f2)

    if (( $W > $H )) ; then
        FORMAT="landscape"
        $SCR_DIR/aspectpad -a 1.5 -m l -p black $IMG new/$IMG
    elif (( $W < $H )) ; then
        FORMAT="portrait"
        $SCR_DIR/aspectpad -a 1.5 -m p -p black $IMG new/$IMG
    else
        FORMAT="squared"
    fi

    echo "$IMG    $SIZE    $FORMAT"
done

cd $OLD_DIR

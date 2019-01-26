#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        git_update_repos.sh
#
# Description:  Given a directory that contains a lot nested directories with
#               many GIT projects, this script updates all the GIT projects code
#               to the latest version.
#
# Usage:        ./git_update_repos.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

GIT_BASE_DIR=/usr/local/src/GIT


# FUNCTIONS --------------------------------------------------------------------

check_cmd () {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" >&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"git"
);

for CMD in ${CMDS[@]} ; do
    check_cmd $CMD
done


# MAIN -------------------------------------------------------------------------

CUR_DIR=$(pwd)

for DIR in $(find $GIT_BASE_DIR -name ".git" | sed -e 's/\/.git//g') ; do
    cd $DIR

    PROJ=$(git remote -v | head -n1 | awk '{print $2}' | sed -e 's,.*:\(.*/\)\?,,' -e 's/\.git$//')

    echo "---- $PROJ"

    git pull

    echo
done

cd $CUR_DIR


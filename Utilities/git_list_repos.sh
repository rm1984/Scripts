#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        git_list_repos.sh
#
# Description:  Given a directory that contains a lot of nested directories with
#               many GIT projects, this script lists all the projects'
#               directories with their relative GIT project's remote URL.
#
# Usage:        ./git_list_repos.sh
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

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"git"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

CUR_DIR=$(pwd)

for DIR in $(find $GIT_BASE_DIR -name ".git" | sed -e 's/\/.git//g' | sort) ; do
    cd $DIR

    URL=$(git remote -v | grep fetch | awk '{print $2}')

    echo "DIR:    ${DIR}"
    echo "URL:    ${URL}"

    echo
done

cd $CUR_DIR


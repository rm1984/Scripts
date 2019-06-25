#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        quick_backup.sh
#
# Description:  A script that makes a quick and simple TAR.GZ encrypted backup
#               of the specified directories.
#
# Usage:        ./quick_backup.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DIRS_TO_BACKUP=(
/etc/
/var/www/
)

OUT_FILE=/tmp/BACKUP$(date +_%Y%m%d_%H%M%S).tar.gz


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"ccrypt"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

echo "Directories to backup:"
echo "${DIRS_TO_BACKUP[@]}" | tr ' ' '\n'
echo
echo "Output file:"
echo $OUT_FILE
echo

tar -czf - $(echo ${DIRS_TO_BACKUP[*]}) 2> /dev/null | ccrypt > $OUT_FILE


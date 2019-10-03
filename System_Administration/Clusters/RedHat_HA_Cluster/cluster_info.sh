#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        cluster_info.sh
#
# Description:  A script that shows some information about running resources in
#               resource groups on a RHEL 7 cluster.
#
# Usage:        ./cluster_info.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

WIDTH=18


# FUNCTIONS --------------------------------------------------------------------

command_exists () {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" >&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2
    exit 1
fi

declare -a CMDS=(
"crmadmin"
"pcs"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

printf "%-${WIDTH}s %-${WIDTH}s %-${WIDTH}s %-${WIDTH}s\n" GROUP RESOURCE TYPE NODE
echo "--------------------------------------------------------------------------------"

DESIGNATED_CONTROLLER=$(crmadmin -D | grep "Designated Controller" | awk 'END {print $NF}')

while read -r GROUPS_AND_RESOURCES ; do
	GROUP_AND_RESOURCES=($GROUPS_AND_RESOURCES)
	GROUP=${GROUP_AND_RESOURCES[0]}
	RESOURCES=${GROUP_AND_RESOURCES[@]:1}

	for RESOURCE in $RESOURCES ; do
		TYPE=$(pcs resource show $RESOURCE | grep Resource | sed -e 's/)//g')
		TYPE=${TYPE##*=}
		NODE=$(pcs status resources | grep $RESOURCE | awk 'END {print $NF}')

		if [ -n "$DESIGNATED_CONTROLLER" ] && [ "$DESIGNATED_CONTROLLER" = "$NODE" ] ; then
			NODE="$NODE (DC)"
		fi

		printf "%-${WIDTH}s %-${WIDTH}s %-${WIDTH}s %-${WIDTH}s %s\n" $GROUP $RESOURCE $TYPE $NODE
	done
done < <(pcs status groups | sed -e 's/://g')


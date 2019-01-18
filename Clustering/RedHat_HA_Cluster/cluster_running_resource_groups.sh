#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        cluster_running_resource_groups.sh
#
# Description:  A script that shows on which nodes all the resource groups are running.
#
# Usage:        ./cluster_running_resource_groups.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

WIDTH=18


# CHECKS -----------------------------------------------------------------------

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2
    exit 1
fi

declare -a CMDS=(
"crm_resource"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

while read -r RESOURCE_GROUP
do
	NODE=$($CRM_RESOURCE_COMMAND --resource $RESOURCE_GROUP --locate | awk '{print $NF}')

	printf "%-${WIDTH}s %-${WIDTH}s\n" $RESOURCE_GROUP $NODE
done < <($CRM_RESOURCE_COMMAND --list | grep 'Resource Group' | awk '{print $NF}' | sort)


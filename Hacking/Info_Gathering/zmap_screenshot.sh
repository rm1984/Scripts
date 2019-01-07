#!/bin/bash
#
# Author:       Riccardo Mollo (info@riccardomollo.com)
#
# Name:	        zmap_screenshot.sh
#
# Description:  A script that takes screenshots of all the websites belonging to
#               a whole subnet.
#
# Usage:        ./zmap_screenshot.sh <target> [<port>]
#
#
# --TODO--
# - ???
#
#
################################################################################


# FUNCTIONS --------------------------------------------------------------------

command_exists () {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" >&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"amap"
"cutycapt"
"host"
"ipcalc"
"whois"
"zmap"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

TARGET=$1
PORT=$2
THIS=$(basename "$0")

if [[ -z "$TARGET" ]] ; then
#    echo "Usage:    $THIS <target> [<port>] [<out_dir>]"
    echo "Usage:    $THIS <target> [<port>]"
    echo
    echo "          <target>     -    Initial host (eg: scanme.nmap.org)"
    echo "          <port>       -    Port to check (default: 80)"
#    echo "          <out_dir>    -    Directory where screnshot are saved (default: /tmp/shots)"

    exit 1
fi

echo "Initial target:         $TARGET"

if [[ -z "$PORT" ]] ; then
    PORT=80

    echo "Port:                   $PORT (default)"
else
    echo "Port:                   $PORT"
fi

IP=$(host $TARGET | grep 'has address' | grep -v 'IPv6' | grep -v 'NXDOMAIN' | awk '{print $NF}' | head -1)

if [[ -z "$IP" ]] ; then
    echo "Wrong target format or target not resolvable."

    exit 1
fi

OUT_DIR="/tmp/shots_${TARGET}"
mkdir $OUT_DIR

echo "Target's IP address:    $IP"

RANGE=$(whois $IP | egrep 'inetnum:|NetRange:' | head -1 | cut -d':' -f2 | xargs | tr -d ' ')

echo "IP addresses range:     $RANGE"

NETWORK=$(ipcalc "$RANGE" | tail -1)

echo "Range network:          $NETWORK"

FILENAME="${TARGET}_$(echo "$NETWORK" | sed -e 's/\//_/g').txt"

sudo zmap -p $PORT -o $FILENAME -q --disable-syslog "${NETWORK}"

echo "Discovered IPs file:    $FILENAME"
echo "Discovered hosts   :    $(cat $FILENAME | wc -l)"

for IP in $(cat $FILENAME) ; do
    TEST_HTTPS=$(amap -1 -q $IP $PORT | grep 'matches ssl')
    TEST_HTTPS=$?
    TEST_HTTP=$(amap -1 -q $IP $PORT | grep 'matches http')
    TEST_HTTP=$?

    if [[ $TEST_HTTPS -eq 0 && $TEST_HTTP -ne 0 ]] ; then           # HTTPS
        PROTOCOL="https"
    elif [[ $TEST_HTTP -eq 0 && $TEST_HTTPS -ne 0 ]] ; then         # HTTP
        PROTOCOL="http"
    elif [[ $TEST_HTTP -eq 0 && $TEST_HTTPS -eq 0 ]] ; then         # probably HTTPS
        PROTOCOL="https"
    else
        echo "Skipping host $IP (unknown protocol for port $PORT)"

        continue
    fi

    echo "Saving screenshot for site: $PROTOCOL://$IP:$PORT"

    cutycapt --insecure --out=$OUT_DIR/$IP.jpg --smooth --private-browsing=on --max-wait=5000 --url="$PROTOCOL://$IP:$PORT" 2> /dev/null
done

#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        share_file.sh
#
# Description:  A script that lets a user share just *one* specific file to
#               somebody else by just sending him a simple URL.
#               No path/subdirectory is present in the URL, so the file name is
#               never mentioned. However, when the recipient will download the
#               file, it will be saved with its original name.
#               This tool makes use of NGROK (https://ngrok.com/).
#
#               NOTE: please remember to kill the "nc" and "ngrok" processes as
#               soon as the file has been downloaded.
#
# Usage:        ./share_file.sh <FILE>
#
#
# --TODO--
# - handle processes' kills when the file is downloaded
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

PORT=31337    # port on localhost that NetCat will bind to
WAIT=3        # seconds to wait before asking NGROK the public URL


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"curl"
"jq"
"nc"
"ngrok"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------


FILE=$1

if [[ ! -f ${FILE} ]] ; then
   echo "Error! File not found: ${FILE}"

   exit 1
fi

CDFN=$(basename ${FILE})
SIZE=$(wc -c ${FILE} | awk '{ print $1 }')
bold='\033[1m'
normal='\033[0m'

echo "Sharing file \"${FILE}\" (size in bytes: ${SIZE})..."

{ echo -ne "HTTP/1.0 200 OK\r\nContent-Disposition: attachment; filename=\"${CDFN}\"\r\nContent-Length: ${SIZE}\r\n\r\n"; cat ${FILE}; } | nc -n -l ${PORT} >/dev/null 2>&1 &

echo "Launching NGROK for \"http://127.0.0.1:${PORT}/\"..."

nohup ngrok http "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 &
sleep ${WAIT}

PURL=$(curl --silent http://127.0.0.1:4040/api/tunnels | jq -r --unbuffered '.tunnels[0].public_url')

echo
echo -e "****    Public URL:    ${bold}${PURL}${normal}    ****"
echo
echo "Now you can download \"${CDFN}\" with a browser or with one of the following commands:"
echo "$ wget --content-disposition ${PURL}"
echo "$ curl -JLO ${PURL}"
echo

#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nessus_massive_export.sh
#
# Description:  When working with Nessus vulnerability scanner, if you have a
#               lot of scans in a folder, it takes a boringly long time to
#               download all the exports by hand.
#               This scripts lets you download the exports of all the scans in
#               a folder in just one shot.
#
# Usage:        ./nessus_massive_export.sh
#
#
# --TODO--
# - list all the folders with their IDs
# - pass folder ID as script parameter
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

HOSTADDR="192.168.1.34" # the IP address of your Nessus scanner machine
USERNAME="nessus_user"
PASSWORD='nessus_password'
FOLDERID=16 # folder ID (eg: https://192.168.1.34:8834/#/scans/folders/16)

REPORTSD="/tmp/reports" # directory that will contain XML files exported from Nessus
SLEEPSEC=10 # seconds to wait to let Nessus generate the export file


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"curl"
"gunzip"
"jq"
"jsonlint"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

AUTH=$(curl -s -k  -X $'POST' \
    -H $"Host: ${HOSTADDR}:8834" -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0' -H $'Accept: */*' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $"Referer: https://${HOSTADDR}:8834/" -H $'Content-Type: application/json' -H $'X-API-Token: 00000000-0000-0000-0000-000000000000' -H $'Content-Length: 55' -H $'Connection: close' \
    --data-binary $"{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    $"https://${HOSTADDR}:8834/session" | jsonlint -f | grep token | awk '{ print $4 }' | tr -d '"')

if [[ -z "$AUTH" ]] ; then
    echo "Error! Cannot authenticate."
    exit 1
fi

echo "AUTH Token: ${AUTH}"

curl -s -k  -X $'GET' \
    -H $"Host: ${HOSTADDR}:8834" -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0' -H $'Accept: */*' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $"Referer: https://${HOSTADDR}:8834/" -H $'Content-Type: application/json' -H $'X-API-Token: 00000000-0000-0000-0000-000000000000' -H $"X-Cookie: token=${AUTH}" -H $'Connection: close' \
    $"https://${HOSTADDR}:8834/scans?folder_id=${FOLDERID}" -o scans.gz

gzip -t scans.gz 2>/dev/null

if [[ $? -eq 0 ]] ; then
    gunzip scans.gz
else
    mv scans.gz scans
fi

mkdir -p "${REPORTSD}"

for SCANID in $(cat scans | jq -M ".scans" | grep -F '"id":' | awk '{ print $NF }' | tr -d ',' | sort -h) ; do
    curl -s -k  -X $'POST' \
    -H $"Host: ${HOSTADDR}:8834" -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0' -H $'Accept: */*' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $"Referer: https://${HOSTADDR}:8834/" -H $'Content-Type: application/json' -H $'X-API-Token: 00000000-0000-0000-0000-000000000000' -H $"X-Cookie: token=${AUTH}" -H $'Content-Length: 19' -H $'Connection: close' \
    --data-binary $'{\"format\":\"nessus\"}' \
    $"https://${HOSTADDR}:8834/scans/${SCANID}/export?limit=2500" -o $SCANID.json

    TOKEN=$(cat $SCANID.json | jsonlint -f | grep -F '"token"' | awk '{ print $NF }' | tr -d '"')

    if [[ ! -z "$TOKEN" ]] ; then
        echo -n "Scan ID: ${SCANID} (token: ${TOKEN}) ... "

        sleep $SLEEPSEC

        curl -s -k  -X $'GET' \
        -H $"Host: ${HOSTADDR}:8834" -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0' -H $'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H $'Accept-Language: en-US,en;q=0.5' -H $'Accept-Encoding: gzip, deflate' -H $"Referer: https://${HOSTADDR}:8834/" -H $'Connection: close' -H $'Upgrade-Insecure-Requests: 1' \
        $"https://${HOSTADDR}:8834/tokens/${TOKEN}/download" -o ${REPORTSD}/report_${SCANID}.gz

        gzip -t ${REPORTSD}/report_${SCANID}.gz 2>/dev/null

        if [[ $? -eq 0 ]] ; then
            gunzip ${REPORTSD}/report_${FOLDER_ID}.gz
            mv ${REPORTSD}/report_${FOLDER_ID} ${REPORTSD}/report_${FOLDER_ID}.nessus
        else
            mv ${REPORTSD}/report_${FOLDER_ID}.gz ${REPORTSD}/report_${FOLDER_ID}.nessus
        fi

        echo "OK"
    fi
done

rm -f *.json
rm -f scans

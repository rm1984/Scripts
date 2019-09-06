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
# Usage:        ./nessus_massive_export.sh [FOLDER_ID]
#
# Notes:        Tested on Nessus Professional 8.5.1.
#               It may not work with older versions.
#
#
# --TODO--
# - make it work with older versions
# - do checks when there are no folders or no scans in a folder
# - do checks on potential server timeouts and longer time to sleep
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

HOSTADDR="192.168.1.34" # the IP address of your Nessus scanner machine
USERNAME="nessus_user"
PASSWORD='nessus_password'

REPORTSD="/tmp/reports" # directory that will contain XML files exported from Nessus
SLEEPSEC=10 # seconds to wait to let Nessus generate the export file
UA="cURL/7.65.3"
#UA="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:60.0) Gecko/20100101 Firefox/60.0"


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"column"
"curl"
"gunzip"
"gzip"
"jq"
"jsonlint"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ "$#" -ge 2 ]] ; then
    echo "./nessus_massive_export.sh [FOLDER_ID]"
    echo

    exit 1
fi

AUTH=$(curl -s -k -X $"POST" \
    -H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Content-Type: application/json" -H $"Content-Length: 55" -H $"Connection: close" \
    --data-binary $"{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    $"https://${HOSTADDR}:8834/session" | jsonlint -f | grep token | awk '{ print $4 }' | tr -d '"')

if [[ -z "$AUTH" ]] ; then
    echo "Authentication error for user \"${USERNAME}\"! Quitting..."
    echo

    exit 1
fi

curl -s -k -X $"GET" \
-H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $'Referer: https://10.70.80.10:8834/' -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
$"https://${HOSTADDR}:8834/server/properties" -o properties.gz

if [[ $? -eq 0 ]] ; then
    gunzip -q --synchronous properties.gz
else
    mv properties.gz properties
fi

VERSION=$(cat properties | jq -M '.nessus_type, .server_version' | tr -d '\n' | sed -e 's/""/ /g' | tr -d '"')
MAJOR_VERSION=$(echo $VERSION | cut -d'.' -f1)

rm -f properties

echo "Scanner version:  ${VERSION}"
echo "     AUTH Token:  ${AUTH}"

if [[ "$#" -eq 0 ]] ; then
    curl -s -k -X $"GET" \
    -H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $'Referer: https://10.70.80.10:8834/' -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
    $"https://${HOSTADDR}:8834/folders" -o folders.gz

    gzip -t folders.gz 2>/dev/null

    if [[ $? -eq 0 ]] ; then
        gunzip -q --synchronous folders.gz
    else
        mv folders.gz folders
    fi

    echo

    cat folders | jq -M -S -c '.folders[] | {name, id}' | jq -M -s 'sort_by(.name)' | grep -Ev '\[|\]|{|}' | cut -d':' -f2 | sed -z 's/,\n//g' | column

    rm -f folders
elif [[ "$#" -eq 1 ]] ; then
    FOLDERID=$1

    curl -s -k -X $"GET" \
    -H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
    $"https://${HOSTADDR}:8834/scans?folder_id=${FOLDERID}" -o scans.gz

    gzip -t scans.gz 2>/dev/null

    if [[ $? -eq 0 ]] ; then
        gunzip -q --synchronous scans.gz
    else
        mv scans.gz scans
    fi

    mkdir -p "${REPORTSD}"

    echo "    Reports dir:  ${REPORTSD}"
    echo "     Sleep time:  ${SLEEPSEC} seconds"
    echo

    for SCANID in $(cat scans | jq -M ".scans" | grep -F '"id":' | awk '{ print $NF }' | tr -d ',' | sort -h) ; do
        ### TODO: test for old versions
        #curl -s -k -X $"POST" \
        #-H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Content-Length: 19" -H $"Connection: close" \
        #--data-binary $'{\"format\":\"nessus\"}' \
        #$"https://${HOSTADDR}:8834/scans/${SCANID}/export" -o $SCANID.json

        curl -s -k -X $"POST" \
        -H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Content-Length: 19" -H $"Connection: close" \
        --data-binary $'{\"format\":\"nessus\"}' \
        $"https://${HOSTADDR}:8834/scans/${SCANID}/export?limit=2500" -o $SCANID.json

        TOKEN=$(cat $SCANID.json | jsonlint -f | grep -F '"token"' | awk '{ print $NF }' | tr -d '"')

        if [[ ! -z "$TOKEN" ]] ; then
            echo -n "Scan ID: ${SCANID} (token: ${TOKEN}) ... "

            sleep $SLEEPSEC

            ### TODO: test for old versions
            #curl -s -k -X $"GET" \
            #-H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Connection: close" -H $"Upgrade-Insecure-Requests: 1" \
            #$"https://${HOSTADDR}:8834/scans/exports/${TOKEN}/download" -o ${REPORTSD}/report_${SCANID}.gz

            curl -s -k -X $"GET" \
            -H $"Host: ${HOSTADDR}:8834" -H $"${UA}" -H $"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:8834/" -H $"Connection: close" -H $"Upgrade-Insecure-Requests: 1" \
            $"https://${HOSTADDR}:8834/tokens/${TOKEN}/download" -o ${REPORTSD}/report_${SCANID}.gz

            gzip -t ${REPORTSD}/report_${SCANID}.gz 2>/dev/null

            if [[ $? -eq 0 ]] ; then
                gunzip -q --synchronous ${REPORTSD}/report_${SCANID}.gz

                mv ${REPORTSD}/report_${SCANID} ${REPORTSD}/report_${SCANID}.nessus
            else
                mv ${REPORTSD}/report_${SCANID}.gz ${REPORTSD}/report_${SCANID}.nessus
            fi

            echo "OK"
        fi
    done

    rm -f scans
    rm -f *.json
fi

echo


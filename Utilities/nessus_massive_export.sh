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

HOSTADDR="192.168.1.34" # the IP address of your Nessus scanner
HOSTPORT="8834" # the TCP port of your Nessus scanner (default: 8834)
USERNAME="nessus_user"
PASSWORD='nessus_password'

TMPDIR="/tmp/.nme" # directory that will contain temporary files
REPORTSDIR="${TMPDIR}/reports" # directory that will contain XML ".nessus" files exported from Nessus
SLEEPSEC=10 # seconds to wait to let Nessus generate the export file
UA="cURL/7.65.3" # custom user agent
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
"nc"
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

cat /dev/null | nc -N ${HOSTADDR} ${HOSTPORT} &> /dev/null

if [[ $? -ne 0 ]] ; then
    echo "TCP port ${HOSTPORT} at host ${HOSTADDR} seems to be closed. Quitting..."
    echo

    exit 1
fi

AUTH=$(curl -s -k -X $"POST" \
    -H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Content-Type: application/json" -H $"Content-Length: 55" -H $"Connection: close" \
    --data-binary $"{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    $"https://${HOSTADDR}:${HOSTPORT}/session" | jsonlint -f | grep token | awk '{ print $4 }' | tr -d '"')

if [[ -z "$AUTH" ]] ; then
    echo "Authentication error for user \"${USERNAME}\"! Quitting..."
    echo

    exit 1
fi

mkdir -p $TMPDIR

curl -s -k -X $"GET" \
-H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $'Referer: https://10.70.80.10:${HOSTPORT}/' -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
$"https://${HOSTADDR}:${HOSTPORT}/server/properties" -o $TMPDIR/properties.gz

if [[ $? -eq 0 ]] ; then
    gunzip -q --synchronous $TMPDIR/properties.gz
else
    mv $TMPDIR/properties.gz $TMPDIR/properties
fi

VERSION=$(cat $TMPDIR/properties | jq -M '.nessus_type, .server_version' | tr -d '\n' | sed -e 's/""/ /g' | tr -d '"')
MAJOR_VERSION=$(echo $VERSION | cut -d'.' -f1)

rm -f $TMPDIR/properties

echo "Scanner version:  ${VERSION}"
echo "    Scanner URL:  https://${HOSTADDR}:${HOSTPORT}/"
echo "     AUTH token:  ${AUTH}"

if [[ "$#" -eq 0 ]] ; then
    curl -s -k -X $"GET" \
    -H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $'Referer: https://10.70.80.10:${HOSTPORT}/' -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
    $"https://${HOSTADDR}:${HOSTPORT}/folders" -o $TMPDIR/folders.gz

    gzip -t $TMPDIR/folders.gz 2>/dev/null

    if [[ $? -eq 0 ]] ; then
        gunzip -q --synchronous $TMPDIR/folders.gz
    else
        mv $TMPDIR/folders.gz $TMPDIR/folders
    fi

    echo

    cat $TMPDIR/folders | jq -M -S -c '.folders[] | {name, id}' | jq -M -s 'sort_by(.name)' | grep -Ev '\[|\]|{|}' | cut -d':' -f2 | sed -z 's/,\n//g' | column
    rm -f $TMPDIR/folders

    echo
elif [[ "$#" -eq 1 ]] ; then
    FOLDERID=$1

    curl -s -k -X $"GET" \
    -H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Connection: close" \
    $"https://${HOSTADDR}:${HOSTPORT}/scans?folder_id=${FOLDERID}" -o $TMPDIR/scans.gz

    gzip -t $TMPDIR/scans.gz 2>/dev/null

    if [[ $? -eq 0 ]] ; then
        gunzip -q --synchronous $TMPDIR/scans.gz
    else
        mv $TMPDIR/scans.gz $TMPDIR/scans
    fi

    rm -rf ${REPORTSDIR}
    mkdir -p ${REPORTSDIR}

    echo "      Folder ID:  ${FOLDERID}"
    echo " Temp files dir:  ${TMPDIR}"
    echo "    Reports dir:  ${REPORTSDIR}"
    echo "     Sleep time:  ${SLEEPSEC} seconds"
    echo

    for SCANID in $(cat $TMPDIR/scans | jq -M ".scans" | grep -F '"id":' | awk '{ print $NF }' | tr -d ',' | sort -h) ; do
        ### TODO: test for old versions
        #curl -s -k -X $"POST" \
        #-H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Content-Length: 19" -H $"Connection: close" \
        #--data-binary $'{\"format\":\"nessus\"}' \
        #$"https://${HOSTADDR}:${HOSTPORT}/scans/${SCANID}/export" -o $TMPDIR/$SCANID.json

        curl -s -k -X $"POST" \
        -H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: */*" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Content-Type: application/json" -H $"X-Cookie: token=${AUTH}" -H $"Content-Length: 19" -H $"Connection: close" \
        --data-binary $'{\"format\":\"nessus\"}' \
        $"https://${HOSTADDR}:${HOSTPORT}/scans/${SCANID}/export?limit=2500" -o $TMPDIR/$SCANID.json

        TOKEN=$(cat $TMPDIR/$SCANID.json | jsonlint -f | grep -F '"token"' | awk '{ print $NF }' | tr -d '"')

        if [[ ! -z "$TOKEN" ]] ; then
            echo -n "Scan ID: ${SCANID} (token: ${TOKEN}) ... "

            sleep $SLEEPSEC

            ### TODO: test for old versions
            #curl -s -k -X $"GET" \
            #-H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Connection: close" -H $"Upgrade-Insecure-Requests: 1" \
            #$"https://${HOSTADDR}:${HOSTPORT}/scans/exports/${TOKEN}/download" -o ${REPORTSDIR}/report_${SCANID}.gz

            curl -s -k -X $"GET" \
            -H $"Host: ${HOSTADDR}:${HOSTPORT}" -H $"${UA}" -H $"Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H $"Accept-Language: en-US,en;q=0.5" -H $"Accept-Encoding: gzip, deflate" -H $"Referer: https://${HOSTADDR}:${HOSTPORT}/" -H $"Connection: close" -H $"Upgrade-Insecure-Requests: 1" \
            $"https://${HOSTADDR}:${HOSTPORT}/tokens/${TOKEN}/download" -o ${REPORTSDIR}/report_${SCANID}.gz

            gzip -t ${REPORTSDIR}/report_${SCANID}.gz 2>/dev/null

            if [[ $? -eq 0 ]] ; then
                gunzip -q --synchronous ${REPORTSDIR}/report_${SCANID}.gz

                mv ${REPORTSDIR}/report_${SCANID} ${REPORTSDIR}/report_${SCANID}.nessus
            else
                mv ${REPORTSDIR}/report_${SCANID}.gz ${REPORTSDIR}/report_${SCANID}.nessus
            fi

            echo "OK"
        fi
    done

    COUNT=$(ls -la ${REPORTSDIR}/*.nessus 2> /dev/null | wc -l)

    if [[ $COUNT -eq 0 ]] ; then
        echo "The folder seems to be empty, so no reports have been exported."
    else
        echo
        echo "${COUNT} reports have been saved."
    fi

    echo

    rm -f $TMPDIR/scans
    rm -f $TMPDIR/*.json
fi


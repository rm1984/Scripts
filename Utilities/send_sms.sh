#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        send_sms.sh
#
# Description:  A script that sends a SMS from an Android device connected via
#               USB to your PC. It needs ADB to work, and "Developer options"
#               must be enabled on your phone.
#
# Usage:        ./send_sms.sh <phone_number> '<message>'
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

NUMBER=$1
MESSAGE=$2


# FUNCTIONS --------------------------------------------------------------------

ommand_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"adb"
);

for CMD in ${CMDS[@]} ; do
    ommand_exists $CMD
done


# MAIN -------------------------------------------------------------------------

adb shell service call isms 7 i32 0 s16 "com.android.mms.service" s16 "\"${NUMBER}\"" s16 "null" s16 "\"${MESSAGE}\"" s16 "null" s16 "null"


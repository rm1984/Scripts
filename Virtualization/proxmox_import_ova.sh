#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        proxmox_import_ova.sh
#
# Description:  A script that helps importing an Open Virtual Appliance (OVA)
#               into ProxMox. A new VM gets created.
#
# Usage:        ./proxmox_import_ova.sh <OVA_FILE>
#
#
# --TODO--
# - improve and optimize code
# - better checks for command line parameters
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

STORAGE="VM_STORAGE"


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"qm"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ "$#" -eq 0 ]] ; then
    echo "./proxmox_import_ova.sh <OVA_FILE>"

    exit 1
fi

OVA=$1

if [[ ! -f "$OVA" ]] ; then
    echo "Error! OVA file not found: $OVA"
    echo

    exit 1
fi

LATEST_VMID=$(qm list | awk '{ print $1 }' | grep -v VMID | sort -h | tail -1)
NEW_VMID=$((LATEST_VMID+1))
TMP=/tmp/.ova_files_list

echo "OVA file:     $OVA"
echo "Latest VMID:  $LATEST_VMID"
echo "New VMID:     $NEW_VMID"
echo "----"
echo "Available storages:"

cat /etc/pve/storage.cfg | grep -F ':' | awk '{ print $NF }'

echo "----"
echo "Uncompressing OVA file..."

tar xvf "$OVA" > "$TMP"

echo "Importing OVF file..."

OVF=$(echo $OVA | sed -e 's/.ova/.ovf/g')
qm importovf $NEW_VMID "$OVF" "$STORAGE"

echo "Deleting old files..."

while read LINE ; do
    rm -f "$LINE"
done < "$TMP"

rm -f "$TMP"

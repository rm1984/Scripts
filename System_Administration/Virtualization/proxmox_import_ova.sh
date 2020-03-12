#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
# Modified by:  Giuseppe Patania (pataniag@gmail.com)
#
# Name:	        proxmox_import_ova.sh
#
# Description:  A script that helps importing an Open Virtual Appliance (OVA)
#               into ProxMox. A new VM gets created.
#
# Usage:        ./proxmox_import_ova.sh --storages
#               ./proxmox_import_ova.sh <OVA_FILE> <DEST_STORAGE>
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

usage() {
    echo "./proxmox_import_ova.sh --storages"
    echo "./proxmox_import_ova.sh <OVA_FILE> <DEST_STORAGE>"
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"awk"
"mktemp"
"pvesh"
"qm"
"tail"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

if [[ "$#" -eq 0 ]] ; then
    usage

    exit 1
elif [[ "$#" -eq 1 && "$1" == "--storages" ]] ; then
    echo "Available storages in ProxMox cluster:"

    pvesh get /storage --noborder --noheader
elif [[ "$#" -eq 2 ]] ; then
    OVA=$1
    STORAGE=$2

    if [[ ! -f "$OVA" ]] ; then
        echo "Error! OVA file not found: $OVA"
        echo

        exit 1
    fi

    TFILE1=$(mktemp)
    TFILE2=$(mktemp)

    pvesh get /nodes --noborder --noheader | awk '{ print $1 }' > $TFILE1

    for NODE in $(cat $TFILE1) ; do
        pvesh get /nodes/$NODE/qemu --noborder --noheader | awk '{ print $2 }' >> $TFILE2
    done

    LATEST_VMID=$(sort -h $TFILE2 | tail -1)
    NEW_VMID=$((LATEST_VMID+1))

    echo "OVA file:     $OVA"
    echo "Storage:      $STORAGE"
    echo "Latest VMID:  $LATEST_VMID"
    echo "New VMID:     $NEW_VMID"
    echo "----"
    echo "Uncompressing OVA file..."

    tar xvf $OVA > $TFILE1

    echo "Importing OVF file..."

    OVF=$(echo $OVA | sed -e 's/.ova/.ovf/g')
    qm importovf $NEW_VMID "$OVF" "$STORAGE"

    echo "Deleting old files..."

    while read LINE ; do
        rm -f $LINE
    done < $TFILE1

    rm -f $TFILE1 $TFILE2

    exit 0
else
    usage

    exit 1
fi

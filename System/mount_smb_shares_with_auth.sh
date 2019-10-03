#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        mount_smb_shares_with_auth.sh
#
# Description:  Given valid credentials, this script lists and mounts all the
#               readable(/writable) shares from a given SMB server.
#
# Usage:        ./mount_smb_shares_with_auth.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

USERNAME='testuser'
PASSWORD='Passw0rd!'
  DOMAIN='TEST'
HOSTNAME='dc.test.local'
MOUNTDIR=/tmp/CIFS


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "ERROR! Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"mount.cifs"
"smbmap"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

echo "Username:  $USERNAME"
echo "Domain:    $DOMAIN"
echo "Host:      $HOSTNAME"
echo
echo "Shares found on \"$HOSTNAME\":"

#enum4linux -u $USERNAME -p $PASSWORD -w $DOMAIN -S $HOSTNAME | grep ^'//' | grep -vF '[E]'

for SHARE in $(smbmap -u $USERNAME -p $PASSWORD -d $DOMAIN -H $HOSTNAME | grep 'READ' | awk '{ print $1 }') ; do
    echo "//$HOSTNAME/$SHARE"

    S=$MOUNTDIR/$SHARE

    umount -q $S
    mkdir -p $S

    mount.cifs -o ro,user=$USERNAME,password=$PASSWORD,domain=$DOMAIN "//$HOSTNAME/$SHARE" $S
done

echo
echo "Mounted shares can be found in:"
echo $MOUNTDIR
echo

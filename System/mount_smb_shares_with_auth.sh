#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        mount_smb_shares_with_auth.sh
#
# Description:  Given valid credentials, this script lists and mount all the
#               readable shares from a given SMB server.
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

U='testuser'
P='Passw0rd!'
W='TEST'
H='dc.test.local'
D=/tmp/CIFS


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

echo "Username: $U"
echo "Domain:   $W"
echo "Host:     $H"
echo
echo "Shares found on \"$H\":"

#enum4linux -u $U -p $P -w $W -S $H | grep ^'//' | grep -vF '[E]'

for SHARE in $(smbmap -u $U -p $P -d $W -H $H | grep 'READ' | awk '{ print $1 }') ; do
    echo "//$H/$SHARE"
    S=$D/$SHARE
    umount -q $S
    mkdir -p $S
    mount.cifs -o ro,user=$U,password=$P,domain=$W "//$H/$SHARE" $S
done

echo
echo "You can find mounted shares in:"
echo $D
echo

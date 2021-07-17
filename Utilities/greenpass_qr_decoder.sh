#!/usr/bin/env bash
#
# Convert a EU Digital COVID Certificate ("Green Pass") QR CODE to text and show its contents.
#
# TOOD:
# - convert binary encoded strings

QRCODE=$1

if [ "$#" -ne 1 ]; then
    echo "Usage: ./gp_qr_decoder.sh <QRCODE.png>"
    exit 1
fi

if [[ ! -f ${QRCODE} ]] ; then
    echo "Image file \"${QRCODE}\" not found."
    exit 1
fi

#sudo pip3 install base45 cbor2
cd /tmp || exit 1
zbarimg "${QRCODE}" > /tmp/pass.txt
sed -e 's/QR-Code:HC1://' < /tmp/pass.txt > /tmp/pass2.txt
base45 --decode < /tmp/pass2.txt > /tmp/pass2.zz
zlib-flate -uncompress < /tmp/pass2.zz > /tmp/pass2.bin
python3 -m cbor2.tool --pretty < /tmp/pass2.bin > /tmp/pass2.dec
cat /tmp/pass2.dec

rm -f /tmp/pass.txt /tmp/pass2.txt /tmp/pass2.zz /tmp/pass2.bin /tmp/pass2.dec

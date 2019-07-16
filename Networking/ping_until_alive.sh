#!/usr/bin/env bash

if [[ $# -ne 1 ]] ; then
    echo "Usage: $0 <IP_ADDRESS>"

    exit 1
fi

IP=$1

echo -n "Pinging $IP "

until ping -4 -D -c 1 -n -O -q -W 1 "$IP" > /dev/null 2>&1 ; do
    echo -n "."
    sleep 1
done

D=$(date +"%a %d %h %Y at %T")
echo -e "\nHost $IP came back alive on $D"

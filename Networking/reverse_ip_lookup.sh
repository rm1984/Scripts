#!/usr/bin/env bash

IP=$1

curl -k https://api.hackertarget.com/reverseiplookup/?q=$IP

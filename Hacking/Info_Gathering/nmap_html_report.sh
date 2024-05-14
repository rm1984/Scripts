#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        nmap_html_report.sh <TARGET>
#
# Description:  A script that runs a full and exhaustive scan against one or
#               more targets, and then creates a nice HTML report using a modern
#               XSL style.
#
# Usage:        ./nmap_html_report.sh <TARGET>
#
#
# --TODO--
# - ???
#
#
################################################################################


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

if [[ $EUID -ne 0 ]] ; then
    echo "This script must be run as root!" 1>&2

    exit 1
fi

declare -a CMDS=(
"nmap"
"curl"
"xsltproc"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

TARGET=$1
SCANNAME="nmap_advanced_portscan"

# check if TARGET is a file (with the list of targets), or just a single host/subnet
if [ -e $TARGET ]; then
    nmap -sS -sV --script=default,version,vuln,ssl-enum-ciphers,ssh-auth-methods,ssh2-enum-algos -Pn --open --min-hostgroup 256 --min-rate 5000 --max-retries 3 --script-timeout 300 -d -oA nmap_advanced_portscan -vvv -iL $TARGET
else
    nmap -sS -sV --script=default,version,vuln,ssl-enum-ciphers,ssh-auth-methods,ssh2-enum-algos -Pn --open --min-hostgroup 256 --min-rate 5000 --max-retries 3 --script-timeout 300 -d -oA nmap_advanced_portscan -vvv $TARGET
fi

# download the XSL style
curl https://raw.githubusercontent.com/Haxxnet/nmap-bootstrap-xsl/main/nmap-bootstrap.xsl -o style.xsl

# apply the XSL style to the XML to obtain the final HTML report
xsltproc -o $SCANNAME.html style.xsl $SCANNAME.xml

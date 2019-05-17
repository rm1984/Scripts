#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        prepare_kali.sh
#
# Description:  A script that installs and configures useful packages on a
#               minimal Kali Linux installation.
#
# Usage:        ./prepare_kali.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

OPENVAS_USER='user'
OPENVAS_PASS='password'


# MAIN -------------------------------------------------------------------------

cat > /etc/apt/sources.list.d/custom.list <<EOL
deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main
deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main
deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic maindeb [arch=amd64] https://packages.microsoft.com/debian/9/prod stretch main
deb [arch=amd64] https://repo.skype.com/deb stable main
deb http://gandalfn.ovh/debian buster-juno main contrib os-patches
deb http://linux.teamviewer.com/deb stable main
deb http://ppa.launchpad.net/elementary-add-team/icons/ubuntu xenial main
deb http://ppa.launchpad.net/elementary-os/stable/ubuntu bionic main
deb http://ppa.launchpad.net/makehuman-official/makehuman-11x/ubuntu devel main
deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main
deb http://prerelease.keybase.io/deb stable main
deb http://repo.mysql.com/apt/debian/ stretch mysql-8.0
deb http://repo.mysql.com/apt/debian/ stretch mysql-apt-config
deb http://repo.mysql.com/apt/debian/ stretch mysql-tools
deb http://repository.spotify.com stable non-free
deb https://deb.nodesource.com/node_11.x jessie main
deb https://download.docker.com/linux/debian stretch stable
deb https://http.kali.org/kali kali-rolling main non-free contrib
deb https://mega.nz/linux/MEGAsync/Debian_9.0/ ./
deb https://wire-app.wire.com/linux/debian stable main
deb-src http://ppa.launchpad.net/elementary-add-team/icons/ubuntu xenial main
deb-src http://ppa.launchpad.net/elementary-os/stable/ubuntu bionic main
deb-src http://ppa.launchpad.net/makehuman-official/makehuman-11x/ubuntu devel main
deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main
deb-src http://repo.mysql.com/apt/debian/ stretch mysql-8.0
deb-src https://deb.nodesource.com/node_11.x jessie main
deb-src https://http.kali.org/kali kali-rolling main non-free contrib
EOL

apt update

# various tools
apt install -y gpm deborphan dnsutils net-tools moreutils colordiff wicd wicd-daemon wicd-curses openvpn htop strace locate rpm nsis elfutils alien vim tcpdump command-not-found mariadb-client xrdp links w3m mssql-tools ntpdate cifs-utils wmi-client keyutils winbind libnss-winbind libpam-winbind irpas wireshark-common snmp snmpcheck acpid acpi arping cifs-utils nfs-common iputils-tracepath open-iscsi ftp freetds-bin screen tmux smem python3-pip socat rsh-client rsync mcrypt libnss3-tools unar facter libpcap-dev libsqlite3-dev gcc graphviz php-cli php-sqlite3 sqlite3 libvmdk-utils libguestfs-tools curlftpfs bsdiff makefs lshw sockstat whois prips

# hacking tools
apt install -y arp-scan sslscan sslyze exploitdb dirb dirbuster netdiscover enum4linux amap smbmap whatweb wafw00f hashid findmyhash fimap theharvester sublist3r dnsenum dnsmap fierce goofile hping3 uniscan whatweb wpscan wordlists samdump2 chntpw passing-the-hash grabber ipcalc zmap metagoofil hydra dnsrecon responder proxychains dsniff creddump nbtscan seclists veil gobuster mimikatz jd-gui jad
apt install -y metasploit-framework msfpc
apt install -y openvas-scanner openvas-manager openvas openvas-cli greenbone-security-assistant-common greenbone-security-assistant

# configure OpenVAS
openvas-feed-update
systemctl restart openvas-scanner.service
openvasmd --rebuild
openvasmd --create-user=$OPENVAS_USER --role=Admin && openvasmd --user=$OPENVAS_USER --new-password=$OPENVAS_PASS
cd /lib/systemd/system
sed -e 's/127.0.0.1/0.0.0.0/g' greenbone-security-assistant.service openvas-manager.service openvas-scanner.service -i


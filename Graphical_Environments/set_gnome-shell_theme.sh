#!/usr/bin/env bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        set_gnome-shell_theme.sh
#
# Description:  A script that sets a Gnome-Shell theme via command line.
#
# Usage:        ./set_gnome-shell_theme.sh [-l | <THEME_NAME>]
#
#
# --TODO--
# - Check themes names
# - List only valid Gnome-Shell themes
# - ???
#
#
################################################################################


# FUNCTIONS --------------------------------------------------------------------

command_exists() {
    command -v "$1" >/dev/null 2>&1 || { echo "Command not found: $1" 1>&2 ; exit 1 ; }
}


# CHECKS -----------------------------------------------------------------------

declare -a CMDS=(
"gsettings"
);

for CMD in ${CMDS[@]} ; do
    command_exists $CMD
done


# MAIN -------------------------------------------------------------------------

OPTION=$1
THIS=$(basename "$0")

if [[ -z "$OPTION" ]] ; then
    echo "Usage:    $THIS [-l | <THEME_NAME>]"
    echo
    echo "          -l | --list  -   List all the available themes"
    echo "          <THEME_NAME> -   Name of the theme to be set"

    exit 1
fi

if [[ "$OPTION" == "-l" || "$OPTION" == "--list" ]] ; then
    ls -A1 /usr/share/themes/
else
    echo "Setting Gnome-Shell theme \""$OPTION"\"..."

    gsettings set org.gnome.desktop.interface gtk-theme \""$OPTION"\"
    gsettings set org.gnome.desktop.wm.preferences theme \""$OPTION"\"
    gsettings set org.gnome.shell.extensions.user-theme name \""$OPTION"\"
fi


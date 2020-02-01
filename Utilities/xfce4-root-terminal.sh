#!/usr/bin/env bash
#
# Since XFCE Terminal doesn't support profiles like Gnome Terminal, this is a simple workaround to start a root terminal.

xhost si:localuser:root
pkexec --user root xfce4-terminal --disable-server --display=:0.0

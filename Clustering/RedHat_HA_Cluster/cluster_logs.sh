#!/bin/bash
#
# Author:       Riccardo Mollo (riccardomollo84@gmail.com)
#
# Name:	        cluster_logs.sh
#
# Description:  A script that shows all the logs of a RHEL 7 cluster (corosync,
#               pacemaker and pcsd).
#
# Usage:        ./cluster_logs.sh
#
#
# --TODO--
# - ???
#
#
################################################################################


# VARIABLES --------------------------------------------------------------------

LOGDIR=/var/log
COROSYNC_LOGFILE=$LOGDIR/cluster/corosync.log
PACEMAKER_LOGFILE=$LOGDIR/pacemaker.log
PCSD_LOGFILE=$LOGDIR/pcsd/pcsd.log


# MAIN -------------------------------------------------------------------------

tail -F $COROSYNC_LOGFILE $PACEMAKER_LOGFILE $PCSD_LOGFILE &


# This script shows the RHEL 7 cluster name in the shell prompt.
# Needs to be saved as: /etc/profile.d/prompt.sh

CLUSTER_NAME=$(pcs config 2> /dev/null | grep 'Cluster Name:' | awk '{print $3}')

if [[ -z $CLUSTER_NAME ]] ; then
	test "$SHELL" == "/bin/bash" && PS1='[\u@\h \w]\$ '
else
	test "$SHELL" == "/bin/bash" && PS1='[$CLUSTER_NAME \u@\h \w]\$ '
fi


#!/bin/bash

echo '==== BEFORE ====' && free && sync && echo 3 > /proc/sys/vm/drop_caches && echo '==== AFTER ====' && free

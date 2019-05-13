#!/bin/bash

aria2c -d /tmp/torrents --bt-metadata-only=true --bt-save-metadata=true --listen-port=6881 "magnet:..."

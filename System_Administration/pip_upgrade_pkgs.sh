#!/usr/bin/env bash

for PKG in $(pip freeze | cut -d'=' -f1) ; do
    pip install $PKG
done

for PKG in $(pip3 freeze | cut -d'=' -f1) ; do
    pip3 install $PKG
done


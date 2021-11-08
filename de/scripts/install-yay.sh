#! /bin/bash

set -e

if [[ "$EUID" -eq 0 ]];
then 
    echo "Can't be run as root"
    exit 1
else 
    builddir=$(mktemp --directory)
    cd ${builddir}

    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si

    rm -rf ${builddir}
fi
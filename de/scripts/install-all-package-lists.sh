#! /bin/bash

set -e

if [[ "$EUID" -eq 0 ]];
then 
    echo "Can't be run as root"
    exit 1
else
    cd $(dirname $(realpath $0))

    if [[ ! -d ../package-lists ]];
    then 
        echo 'This script is only meant to be run on installation, and not copied over to ~/.bin'
        echo 'The anticipated ../package-lists directory was not found'
        exit 1
    else 
        cd ../package-lists
        yay -S --noconfirm $(cat $(ls))
    fi
fi
#! /bin/bash

set -e

trap cleanup EXIT;


# Remove sudo timout so mkpkg isn't run as root, but installation isn't interrupted.

function cleanup () {
    if [[ "${EUID}" -eq 0 ]];
    then 
        if [[ "$(tail -n 1 /etc/sudoers)" == "$(logname) ALL=(ALL) NOPASSWD:ALL" ]];
        then 
            sed -i '$ d' /etc/sudoers
        fi
    fi
}

function main () {
    if [[ ! "$EUID" -eq 0 && "${1}" != 'continue' ]];
    then 
        echo "Must be run as root"
        exit 1
    else
        if [[ ! -d ../package-lists ]];
        then 
            echo 'This script is only meant to be run on installation, and not copied over to ~/.bin'
            echo 'The anticipated ../package-lists directory was not found'
            exit 1
        elif [[ ! $(command -v yay) ]];
        then 
            echo "Run the 'install-yay.sh' script to install yay first"
            exit 1
        else 
            if [[ "${1}" != "continue" ]];
            then 
                echo "$(logname) ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
                su $(logname) -c "/bin/bash install-all-package-lists.sh 'continue'" && 
                cleanup
            else 
                cd ../package-lists
                yay -S --noconfirm $(cat $(ls))
            fi
        fi
    fi
}

main "$@"
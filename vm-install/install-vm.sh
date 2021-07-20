#!/bin/bash

# Note: This script is more opinionated (less flexibility / flags) since it is for a more niche project

function script-usage () {
    cat << EOF
Usage: 
	-f [path] | file			Path to relevant windows iso. Will copy to /usr/local/vms/isopool		(default: ./autowindows.iso)
	-d [dev]  | disk			Entire disk device to pass to vm 										(default: /dev/sda)
EOF
    exit 1
}
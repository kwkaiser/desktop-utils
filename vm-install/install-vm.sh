#!/bin/bash

# Note: This script is more opinionated (less flexibility / flags) since it is for a more niche project

function script-usage () {
    cat << EOF
Usage: 
	-f [path] | file			Path to relevant windows iso. Will copy to /usr/local/vms/isopool		(default: ./autowindows.iso)
	-d [dev]  | disk			Entire disk device to pass to vm 										(default: /dev/sda)
	-h		  | help			Display this screen
EOF
    exit 1
}

function check-root () {
	if [ ${EUID} != 0 ];
	then 
		echo "Run as root; need to mount isos"
		exit 1
	fi
}

function parse-args () {
    ORIGINALARGS="$@"

    while getopts "f:d:" o; do 
        case "${o}" in 
            f)
                ISOPATH=${OPTARG}
				;;
			d)
                INSTALLDISK=${OPTARG}
                ;;
			h)
				script-usage
				exit 1
				;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

function install () {
    virt-install --connect=qemu:///system \
    --name windows \
    --virt-type kvm \
    --boot loader=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
    --memory 1024 \
    --cpu host --vcpus=2,maxvcpus=4 \
    --cdrom ./windows1.iso --disk=/dev/sda
    --network=default
}
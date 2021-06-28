#!/bin/bash

cd $(dirname $(realpath $0))
shopt -s expand_aliases

alias qvirsh="virsh --connect=qemu:///system"

function create-arch-test-pools () {
    qvirsh pool-destroy default 
    qvirsh pool-undefine default 
    qvirsh pool-destroy vmpool 
    qvirsh pool-undefine vmpool 
    qvirsh pool-destroy isopool 
    qvirsh pool-undefine isopool

    qvirsh pool-define-as vmpool dir - - - - "/usr/local/vms/vmpool"
    qvirsh pool-define-as isopool dir - - - - "/usr/local/vms/isopool"

    qvirsh pool-build vmpool 
    qvirsh pool-build isopool

    qvirsh pool-start vmpool 
    qvirsh pool-start isopool 
}

function create-arch-test-vm () {
    qvirsh vol-create-as --pool vmpool --name testvm.qcow2 --capacity 10G --format qcow2
    virt-install --connect=qemu:///system \
        --name testvm \
        --noautoconsole \
        --virt-type kvm \
        --boot loader=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
        --memory 1024 \
        --cpu host \
        --vcpus=2,maxvcpus=4 \
        --cdrom /usr/local/vms/isopool/archlinux-2021.06.01-x86_64.iso \
        --disk size=2,format=qcow2,path=/usr/local/vms/vmpool/testvm.qcow2 \
        --network network=devnetwork,mac=00:11:22:33:44:66 
}

function destroy-arch-test-vm () {
    qvirsh destroy testvm 
    qvirsh undefine testvm

    qvirsh vol-delete --pool vmpool testvm.qcow2
}

function copy-arch-install-tools () {
    rm -rf "${HOME}/.ssh/known_hosts"
    rsync -aP '../../install-utils' root@192.168.122.169:/root/
}

function script-usage () {
    cat << EOF
Usage: 
    -h|help           Display this dialog
    -p|pools          Destroy and recreate pools      
    -v|volumes        Destroy and recreate volumes
    -c|create         Create test vm
    -d|destroy        Destroy test vm
    -y|copy           Copy over install-script suite
EOF
}

function parse_args () {
    if [ "$#" != 1 ];
    then 
        echo 'Illegal number of arguments passed'
        script-usage
        exit 1
    fi

    while getopts "hpvcdy" o; do 
        case "${o}" in 
            h)
                script-usage; exit 1
                ;;
            p)
                create-arch-test-pools
                ;;
            v)  
                create-arch-test-volume
                ;;
            c)
                create-arch-test-vm
                ;;
            d) 
                destroy-arch-test-vm
                ;;
            y) 
                copy-arch-install-tools
                ;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

parse_args "$@"


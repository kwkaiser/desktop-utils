#!/bin/bash

cd $(dirname $(realpath $0))
shopt -s expand_aliases

#############
# UTILITIES #
#############

alias qvirsh="virsh --connect=qemu:///system"

function print-header () {
    LENGTH=${#1}

    echo ''
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ${1}
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ''
}

function script-usage () {
    cat << EOF
Usage: 
    -h|help             Display this dialog
    -p|pools            Destroy and recreate pools      
    -n|network          Create development network. 
    -r|retrieve [link]  Downloads an arch installation iso
    -c|create           Create test vm
    -d|destroy          Destroy test vm
    -y|copy             Copy over install-script suite
EOF
}

function parse-args () {
    while getopts "hpvcdnyr:i:" o; do 
        case "${o}" in 
            h)
                script-usage; exit 1
                ;;
            p)
                create-arch-test-pools
                ;;
            c)
                create-arch-test-vm
                ;;
            d) 
                destroy-arch-test-vm
                ;;
            r)
                retrieve-arch-iso ${OPTARG}
                ;;
            n)
                create-arch-test-network
                ;;
            y) 
                copy-arch-install-tools
                ;;
            i)
                ISOPATH=${OPTARG}
                ;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

######################
# MAIN FUNCTIONALITY #
######################

function create-arch-test-pools () {
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
    if [[ ! -f /usr/local/vms/isopool/arch.iso ]];
    then 
        echo "No arch ISO available under /usr/local/vms/isopool/arch.iso."
        echo "Please add an arch ISO to create the test environment"
        exit 1
    fi

    qvirsh vol-create-as --pool vmpool --name testvm.qcow2 --capacity 50G --format qcow2
    virt-install --connect=qemu:///system \
        --name testvm \
        --noautoconsole \
        --virt-type kvm \
        --boot loader=/usr/share/edk2-ovmf/x64/OVMF_CODE.fd \
        --memory 1024 \
        --cpu host \
        --vcpus=2,maxvcpus=4 \
        --cdrom /usr/local/vms/isopool/arch.iso \
        --disk format=qcow2,path=/usr/local/vms/vmpool/testvm.qcow2 \
        --network network=devnetwork,mac=00:11:22:33:44:66 
}

function destroy-arch-test-vm () {
    qvirsh destroy testvm 
    qvirsh undefine testvm

    qvirsh vol-delete --pool vmpool testvm.qcow2
}

function create-arch-test-network () {
    qvirsh net-define ./confs/devnetwork.xml    
    qvirsh net-start devnetwork
}

function retrieve-arch-iso () {
    wget ${1} -O /usr/local/vms/isopool/arch.iso --show-progress
}

function copy-arch-install-tools () {
    rm -rf "${HOME}/.ssh/known_hosts"
    rsync -aP '../../desktop-utils' root@192.168.122.169:/root/
}

function main () {
    parse-args "$@"
}

main "$@"

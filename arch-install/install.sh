#!/bin/bash

cd $(dirname $(realpath $0))
source ../lib/util.sh

function script-usage () {
    cat << EOF
Usage: 
    -h|help           Display this dialog
    -n|hostname       Hostname for installation                                 (default: hostname)
    -r|root password  Root password to use                                      (default: password)
    -a|account        Account to use                                            (default: kwkaiser)
    -e|encrypted      Whether installation should be encrypted                  (default: false)
    -b|btrfs          Whether to use btrfs instead of ext4                      (default: false)
    -p|prefix         Whether device needs partition prefix (e.g. p for nvme)   (default: none)
    -d|device         Which device to use                                       (default: /dev/sda)
    -s|swap           Size of swap (in MB)                                      (default: 8000)
    -w|wait           Wait to continue after each step                          (default: false)
    -y|Dry run        Print variable summary but do not execute                 (default: false)
EOF
    exit 1
}

function parse-args () {
    ORIGINALARGS="$@"

    while getopts "hn:r:a:ebp:d:s:wy" o; do 
        case "${o}" in 
            h)
                script-usage; exit 1
                ;;
            n)
                HOSTNAME=${OPTARG}
                ;;
            r)  
                ROOTPASS=${OPTARG}
                ;;
            a)
                ACCOUNT=${OPTARG}
                ;;
            e) 
                ENCRYPTED='true'
                ;;
            b) 
                BTRFS='true'
                ;;
            p)
                PREFIX=${OPTARG}
                ;;
            d) 
                DEVICE=${OPTARG}
                ;;
            s)
                SWAP=${OPTARG}
                ;;
            y)
                DRYRUN='true'
                ;;
            w)
                WAIT='true'
                ;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

function initialize-args () {
    HOSTNAME='desktop'
    ROOTPASS='password'
    ACCOUNT='kwkaiser'
    ENCRYPTED='false'
    BTRFS='false'
    PREFIX=''
    DEVICE='/dev/sda'
    SWAP='8000'
    WAIT='false'
    DRYRUN='false'
}

function dry-run () {
    echo "HOSTNAME:         ${HOSTNAME}" 
    echo "ROOTPASS:         ${ROOTPASS}" 
    echo "ACCOUNT:          ${ACCOUNT}" 
    echo "ENCRYPTED:        ${ENCRYPTED}" 
    echo "BTRFS:            ${BTRFS}" 
    echo "PREFIX:           ${PREFIX}" 
    echo "DEVICE:           ${DEVICE}" 
    echo "SWAP:             ${SWAP}" 
    echo "WAIT:             ${WAIT}" 
    echo "DRYRUN:           ${DRYRUN}" 

    exit 1
}

function establish-env () {
    ls /sys/firmware/efi/efivars &> /dev/null 

    if [[ "$?" > 0 ]];
    then
        echo "Missing efivars. Probably not booted under uefi."
        exit 1
    fi
}

function step-wait () {
    if [[ ${WAIT} == 'true' ]];
    then 
        echo ''
        echo 'Press enter to continue to next step, q to exit'
        read local CONTINUE
        echo ''

        if [[ ${CONTINUE} == 'q' ]];
        then
            exit 1
        fi
    fi
}

function partition-disks () {
    print-header 'Paritioning disk'

    sgdisk -Z ${DEVICE}
    sgdisk -og ${DEVICE}

    sgdisk -n 1::+500M -c 1:"boot" -t 1:ef00 ${DEVICE}
    sgdisk -n 2::+${SWAP}M -c 2:"swap" ${DEVICE}
    sgdisk -n 3:: -c 3:"root" ${DEVICE}
}

function encrypt-root () {
    print-header 'Encrypting root partition'
    echo 'You will need to provide an encryption password'

    cryptsetup luksFormat ${DEVICE}${PREFIX}3
    cryptsetup open ${DEVICE}${PREFIX}3 rootpart 
}

function format-partitions () {
    print-header 'Formatting partitions'
    
    mkfs.vfat -F32 -n 'BOOT' ${DEVICE}${PREFIX}1

    mkswap -L 'SWAP' ${DEVICE}${PREFIX}2
    swapon ${DEVICE}${PREFIX}2

    if [[ ${BTRFS} == 'true' ]];
    then
        mkfs.btrfs -L 'ARCHROOT' ${ROOTPART}
    else
        mkfs.ext4 -L 'ARCHROOT' ${ROOTPART}
    fi
}

function make-mounts () {
    print-header 'Creating subvolumes & mount points'

    mount ${ROOTPART} /mnt

    if [[ ${BTRFS} == 'true' ]];
    then
        btrfs sub create /mnt/@
        btrfs sub create /mnt/@home
        btrfs sub create /mnt/@pkg
        btrfs sub create /mnt/@snapshots
        umount /mnt

        mount -o noatime,nodiratime,compress=zstd,space_cache,ssd,subvol=@ ${ROOTPART} /mnt
        mkdir -p /mnt/{boot,home,var/cache/pacman/pkg,.snapshots,btrfs}

        mount -o noatime,nodiratime,compress=zstd,space_cache,ssd,subvol=@home ${ROOTPART} /mnt/home
        mount -o noatime,nodiratime,compress=zstd,space_cache,ssd,subvol=@pkg ${ROOTPART} /mnt/var/cache/pacman/pkg
        mount -o noatime,nodiratime,compress=zstd,space_cache,ssd,subvol=@snapshots ${ROOTPART} /mnt/.snapshots
        mount -o noatime,nodiratime,compress=zstd,space_cache,ssd,subvolid=5 ${ROOTPART} /mnt/btrfs
    fi

    mkdir /mnt/boot
    mount ${DEVICE}${PREFIX}1 /mnt/boot
}

function base-install () {
    print-header 'Updating mirrors & performing base install'
    # reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
    pacstrap /mnt linux base base-devel btrfs-progs intel-ucode vim sudo
}

function generate-fstab () {
    print-header 'Creating fstab and preparing to chroot'

    genfstab -U /mnt >> /mnt/etc/fstab
}

function run-chroot () {
    print-header 'Executing chroot script'

    cp -r ../../arch-utils/ /mnt/arch-utils

    if [[ ${PREFIX} == '' ]];
    then 
        arch-chroot /mnt /bin/bash /arch-utils/arch-install/chroot.sh -n ${HOSTNAME} -r ${ROOTPASS} -a ${ACCOUNT} -e ${ENCRYPTED} -b ${BTRFS} -d ${DEVICE} -y ${DRYRUN} -w ${WAIT} 
    else 
        arch-chroot /mnt /bin/bash /arch-utils/arch-install/chroot.sh -n ${HOSTNAME} -r ${ROOTPASS} -a ${ACCOUNT} -e ${ENCRYPTED} -b ${BTRFS} -d ${DEVICE} -y ${DRYRUN} -w ${WAIT} -p ${PREFIX} 
    fi
}

function main () {
    initialize-args
    parse-args "$@"

    if [[ ${DRYRUN} == 'true' ]];
    then
        dry-run
    fi

    establish-env 

    partition-disks && step-wait

    if [[ ${ENCRYPTED} == 'true' ]];
    then
        encrypt-root && step-wait
        ROOTPART=/dev/mapper/rootpart
    else 
        ROOTPART=${DEVICE}${PREFIX}3
    fi

    format-partitions && step-wait
    make-mounts && step-wait
    base-install && step-wait
    generate-fstab && step-wait
    run-chroot 
}

main "$@" 

#!/bin/bash

cd $(dirname $(realpath $0))
source ../lib/util.sh

function script-usage () {
    cat << EOF
Usage: 
    This script is a helper script to the primary installer script. It should **never** be called
    directly. 

    -h|help           Display this dialog
    -n|hostname       Hostname for installation                                 (default: hostname)
    -r|root password  Root password to use                                      (default: password)
    -a|account        Account to use                                            (default: kwkaiser)
    -e|encrypt        Whether install is encrypted                              (default: false)
    -b|btrfs          Whether install is btrfs                                  (default: false)
    -p|prefix         Whether device needs partition prefix (e.g. p for nvme)   (default: none)
    -d|device         Which device to use                                       (default: /dev/sda)
    -w|wait           Wait to continue after each step                          (default: false)
    -y|Dry run        Print variable summary but do not execute                 (default: false)
EOF
    exit 1
}

function parse-args () {
    while getopts "hn:r:a:e:b:p:d:w:y:" o; do 
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
                ENCRYPTED=${OPTARG}
                ;;
            b) 
                BTRFS=${OPTARG}
                ;;
            p)
                PREFIX=${OPTARG}
                ;;
            d) 
                DEVICE=${OPTARG}
                ;;
            y)
                DRYRUN=${OPTARG}
                ;;
            w)
                WAIT=${OPTARG}
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
    WAIT='false'
    DRYRUN='false'
}

function dry-run () {
    echo "HOSTNAME:         ${HOSTNAME}" 
    echo "ROOTPASS:         ${ROOTPASS}" 
    echo "ACCOUNT:          ${ACCOUNT}" 
    echo "ENCRPYTED:        ${ENCRYPTED}" 
    echo "BTRFS:            ${BTRFS}" 
    echo "PREFIX:           ${PREFIX}" 
    echo "DEVICE:           ${DEVICE}" 
    echo "WAIT:             ${WAIT}" 
    echo "DRYRUN:           ${DRYRUN}" 

    exit 1
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

function assign-hostname () {
    print-header 'Assiging hostname'

    echo ${HOSTNAME} > /etc/hostname
}

function assign-locale () {
    print-header 'Assigning and generating locale'

    echo LANG=en_US.UTF-8 > /etc/locale.conf
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen

    locale-gen
}

function assign-time () {
    print-header 'Setting time'

    ln -sf /usr/share/zoneinfo/American/New_York /etc/localtime
}

function update-hosts () {
    print-header 'Updating hosts file'

    echo "127.0.0.1	localhost" > /etc/hosts
    echo "::1		localhost" >> /etc/hosts
    echo "127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}" >> /etc/hosts
}

function manage-users () {
    print-header 'Updating users'

    groupadd sudo
    useradd --create-home ${ACCOUNT}
    usermod -aG sudo ${ACCOUNT}

    echo "${ACCOUNT}:password" | chpasswd 
    echo "root:${ROOTPASS}" | chpasswd
}

function update-sudoers () {
    print-header 'Updating sudoers file'

    sed -i 's/# %sudo/  %sudo/g' /etc/sudoers
}

function customize-initramfs () {
    print-header 'Adding encryption check to initramfs'

    # Replace old line
    sed -i 's/HOOKS=*/#/g' /etc/mkinitcpio.conf
    echo "HOOKS=(base keyboard udev autodetect modconf block keymap encrypt btrfs filesystems)" >> /etc/mkinitcpio.conf

    mkinitcpio -p linux
}

function create-bootloader () {
    print-header 'Installing bootloader'

    bootctl --path=/boot install 

cat > /boot/loader/entries/arch.conf << EOF
tile Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
EOF

    if [[ ${ENCRYPTED} == 'true' ]];
    then
        if [[ ${BTRFS} == 'true' ]];
        then 
            echo "options rw cryptdevice=${DEVICE}${PREFIX}3:rootpart root='LABEL=ARCHROOT' rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch.conf
        else 
            echo "options rw cryptdevice=${DEVICE}${PREFIX}3:rootpart root='LABEL=ARCHROOT'" >> /boot/loader/entries/arch.conf
        fi 
    else 
        if [[ ${BTRFS} == 'true' ]];
        then 
            echo "options rw root='LABEL=ARCHROOT' rootflags=subvol=@ rd.luks.options=discard rw" >> /boot/loader/entries/arch.conf
        else 
            echo "options rw root='LABEL=ARCHROOT'" >> /boot/loader/entries/arch.conf
        fi 
    fi

cat > /boot/loader/loader.conf << EOF
default arch.conf
timeout 4
console-mode max
editor no
EOF

}

function enable-networking () {
    print-header 'Enabling networking with NetworkManager'

    systemctl enable NetworkManager
}

function update-repos () {
    print-header 'Updating reposistory mirrorlist'

    reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
}

function configure-administrator () {
    print-header 'Adding default user to sudo group'

    echo '%sudo	ALL=(ALL) ALL' >> /etc/sudoers
    usermod -aG sudo ${ACCOUNT}
}

function finish-up () {
    print-header 'Cleaning up. Please exit and reboot'

    mkdir -p /home/${ACCOUNT}/documents/
    mv /desktop-utils /home/${ACCOUNT}/documents/

    chown -R ${ACCOUNT}:${ACCOUNT} /home/${ACCOUNT}/
}


function main () {

    initialize-args
    parse-args "$@"

    if [[ ${DRYRUN} == 'true' ]];
    then
        dry-run
    fi

    assign-hostname && step-wait
    assign-locale && step-wait
    assign-time && step-wait
    update-hosts && step-wait
    manage-users && step-wait
    customize-initramfs  && step-wait
    create-bootloader && step-wait
    enable-networking && step-wait
    update-repos && step-wait
    configure-administrator && step-wait
    finish-up
}

main "$@"

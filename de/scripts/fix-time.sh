#! /bin/bash

if [[ ${EUID} -ne 0 ]];
then 
    echo 'Script must be run as administrator'
    exit 1
else 
    sudo rm -r /etc/localtime
    sudo ln -sr /usr/share/zoneinfo/America/New_York /etc/localtime
    sudo hwclock --systohc --utc
fi
#! /bin/bash

if [[ ${EUID} != 0 ]];
then
    echo 'This script must be run as root'
    exit 1
else 
    declare -a scripts=( 'pomo.sh' 'dmgr.sh')

    declare -a sscripts=( 'mountbox.sh' 'umountbox.sh' )

    for j in ${scripts[@]};
    do
        newpath=/usr/local/bin/$(echo "${j%.*}")
        cp ${j} ${newpath}
        chmod +x ${newpath}
    done

    for i in ${sscripts[@]};
    do
        newpath=/usr/local/sbin/$(echo "${i%.*}")
        cp ${i} ${newpath}
        chmod +x ${newpath}
    done
fi


#! /bin/bash

if [[ ${EUID} != 0 ]];
then
    echo 'This script must be run as root'
    exit 1
else 
    declare -a scripts=('dmgr.sh')

    declare -a sscripts=( 'mountbox.sh' 'umountbox.sh' )

    for i in ${scripts[@]};
    do
        newpath=/usr/local/bin/$(echo "${i%.*}")
        cp ${i} ${newpath}
        chmod +x ${newpath}
    done

    for i in ${sscripts[@]};
    do
        ewpath=/usr/local/sbin/$(echo "${i%.*}")
        cp ${i} ${newpath}
        chmod +x ${newpath}
    done
fi


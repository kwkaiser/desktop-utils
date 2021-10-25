#! /bin/bash

function print-header () {
    LENGTH=${#1}

    echo ''
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ${1}
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ''
}

function check-installed () {
    if [[ -z ${1} ]];
    then 
        echo 1
    else
        if [[ $(pacman -Qs ${1}) ]];
        then 
            echo 0
        else 
            echo 1
        fi
    fi
}

repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}
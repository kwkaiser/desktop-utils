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
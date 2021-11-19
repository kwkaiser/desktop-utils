#! /bin/bash

set -e 

#####################################
# Collection of reference utilities #	
#####################################

################
# String utils #	
################

function repeat-char (){
    local start=1
    local end=${1:-80}
    local str="${2:-=}"
    local range=$(seq $start $end)
    for i in $range ; do echo -n "${str}"; done
}

function print-header () {
    local length=${#1}
    local header=$(repeat-char ${length} '-' )

    printf '%s\n%s\n%s\n' ${header} ${1} ${header}
}

function center() {
  termwidth="$(tput cols)"
  padding="$(printf '%0.1s' ' '{1..500})"
  printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

function print-centered () {
    local cols=$(tput cols)

    while IFS= read -r line; 
    do
        center "${line}"
    done <<< "${1}"
}

#############
# Arg utils #	
#############

function parse-args-template () {
        while :; do
        case "${1-}" in
            -h | --help) 
                script-usage 
                exit 1
                ;;

            -?*) 
                local test='test'
                exit 1
                ;;
            *) 
                break ;;
        esac
        shift
    done
}

function script-usage-template () {
    cat << EOF

Script usage description 
Usage:
    -h | --help         Print this output
EOF
}

#############
# Sys utils #	
#############

function get-terminal () {
    printf $(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")
}
#! /bin/bash

set -e

######################################
# Management for desktop environment #	
######################################

# Utilities

function print-header () {
    LENGTH=${#1}

    echo ''
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ${1}
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ''
}

repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
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

function check-dependencies () {
    if [[ ! $(check-installed pip) -eq 0 || ! $(check-installed fzf) -eq 0 || ! $(check-installed rsync) -eq 0 ]];
    then 
        echo "This script requires:"
        echo "  - ranger"
        echo "  - pip (with pillow installed, locally"
        echo "  - rsync"
        exit 1
    fi
}

# Arg handling

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help         Print this output
    -f | --files        Override dotfiles path (default: ~/dotfiles)
    -i | --interactive  Select a desktop environment theme through ranger browsing
    -t | --theme        Provide a specific path to an environment theme and setup
    -d | --dry          Print out variables, but do not appy theme
EOF
}

function initialize-args () {
    export DOTFILES=${HOME}/dotfiles
    export TTY=$(tty)
    export LINES=$(tput lines)
    export COLS=$(tput cols)
}

function parse-args () {
        while :; do
        case "${1-}" in
            -h | --help) 
                script-usage 
                exit 1
                ;;

            -f | --files)
                DOTFILES=${2-}
                shift 
                ;;

            -t | --theme)

                if [[ -z ${THEME} ]];
                then
                    THEME=${2-}
                else
                    echo "Conflicting theme selection options"
                    exit 1
                fi

                shift
                ;;

            -i | --interactive) 
                THEME=${DOTFILES}/themes/$(ls ${DOTFILES}/themes | fzf --ansi --preview 'print-fzf-summary {}')
                ;; 

            -d | --dry)
                DRYRUN='true'
                ;;

            -?*) 
                script-usage 
                exit 1
                ;;
            *) 
                break ;;
        esac
        shift
    done
}

function check-args () {
    if [[ ! -d ${DOTFILES} ]];
    then 
        echo 'Expected dotfiles directory:'
        echo ${DOTFILES}
        echo 'does not exist. Exiting..'
        exit 1
    fi

    if [[ ! -d ${THEME} || ! -f ${THEME}/colors.txt ]];
    then 
        echo 'Expected theme directory: '
        echo ${THEME}
        echo 'does not exist or is invalid. Exiting..'
        exit 1
    fi
}

# Config handling 

function copy-configs () {
    print-header 'Copying configurations'
    rsync -aP --ignore-times ${DOTFILES}/ ${HOME}/.config
}

# Color and image handling

function source-colors () {
    cd ${THEME}
    source ./colors.txt

    declare -g -A COLORS

    COLORS['bg']=$background
    COLORS['foreground']=$foreground
    COLORS['cursorColor']=$foreground

    for number in {0..15};
    do 
        local varname="color${number}"
        COLORS[${varname}]=${!varname}
    done
}

function print-colors () {
    if [[ -z ${1} ]];
    then 
        local output=/dev/stdout
    else 
        local output=${1}
    fi

    # Color list = ~19 characters, fuzz & look for tput cols / 2 - (color list length / 2)
    local spacer=$(printf "%.0f" $(bc -l <<< "( ${COLS} / 2 ) - (20 / 2) "))

    for i in $(seq 0 15);
    do
        printf "\033]4;${i};${COLORS[color${i}]}\007" > ${output}
        printf "%${spacer}s %10s %5b\n" "COLOR${i}:" ${COLORS[color${i}]} "\e[38;5;${i}m$(repeat 10 "\u2588")\e[0m" 
    done
}

function substitute-colors () {
    print-header 'Substituting colors'

    SUBFILES=$(rsync -aP --dry-run --ignore-times --exclude="meta" ${DOTFILES}/ ${HOME}/.config | tail -n +2)

    for i in ${SUBFILES};
    do  
        if [[ -f ${HOME}/.config/${i} ]];
        then 
            for j in "${!COLORS[@]}"
            do
                sed -i "s/${j}/${COLORS[${j}]}/g" ${HOME}/.config/${i}
            done
        fi
    done 
}

function block-print-background () {
    cd ${THEME} 

    local sized_lines=$(printf "%.0f" $(bc -l <<< "${LINES} * (3/4)"))
    local sized_cols=$(printf "%.0f" $(bc -l <<< "${COLS}"))

    if [[ -f ${THEME}/background.jpg ]];
    then 
        local ending=".jpg"
    else 
        local ending=".png"
    fi

    timg --center -g ${sized_cols}x${sized_lines} ${THEME}/background.jpg 
}

function print-fzf-summary () {
    THEME=${DOTFILES}/themes/${1}
    LINES=$(tput lines)
    COLS=$(tput cols)

    source-colors
    print-colors ${TTY} 
    block-print-background
}

# Run utilities

function dry-run () {
    print-header 'Basics:'
    printf "%5s %10s" 'THEME:' ${THEME}
    echo ''

    print-header 'Copied files:'

    rsync -aP --dry-run --ignore-times ${DOTFILES} ${HOME}/.config/

    print-header 'Colors:'
    print-colors

    print-header 'Background'
    block-print-background

    echo ''
}

function main () {
    check-dependencies
    initialize-args "$@"
    parse-args "$@"
    check-args

    source-colors

    if [[ ${DRYRUN} == 'true' ]];
    then 
        dry-run 
        exit 1
    fi

    copy-configs
    substitute-colors
}

export -f print-header 
export -f repeat 
export -f check-installed
export -f check-dependencies
export -f script-usage 
export -f initialize-args 
export -f parse-args 
export -f check-args 
export -f copy-configs 
export -f source-colors 
export -f print-colors 
export -f substitute-colors 
export -f block-print-background 
export -f print-fzf-summary 
export -f dry-run

main "$@"


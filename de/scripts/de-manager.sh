#! /bin/bash

set -e
trap 'cleanup' EXIT

######################################
# Management for desktop environment #	
######################################

#############
# Utilities #
#############

function print-header () {
    local length=${#1}

    echo ''
    seq -s= ${length}|tr -d '[:digit:]'
    echo ${1}
    seq -s= ${length}|tr -d '[:digit:]'
    echo ''
}

repeat(){
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

function check-dependencies () {
    if [[ ! $(command -v fzf) || ! $(command -v rsync) || ! $(command -v timg) ]];
    then 
        echo 'This script expects three dependencies:'
        echo '  -rsync'
        echo '  -fzf'
        echo '  -timg'
        exit 1
    fi 
}

################
# Arg handling #
################

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help         Print this output
    -f | --files        Override dotfiles path (default: ~/dotfiles)
    -i | --interactive  Select a desktop environment theme through ranger browsing
    -t | --theme        Provide a specific path to an environment theme and setup
    -r | --random       Choose a random theme for environment
    -d | --dry          Print out variables, but do not appy theme
EOF
}

function initialize-args () {
    export DOTFILES=${HOME}/dotfiles
    export TTY=$(tty)
    export LINES=$(tput lines)
    export COLS=$(tput cols)

    if [[ -f ${HOME}/.config/kitty/kitty.conf ]];
    then 
        cp ${HOME}/.config/kitty/kitty.conf /tmp/kitty.tmp
    fi
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
                CHOSEN='true'
                ;; 

            -r | --random)
                THEME=${DOTFILES}/themes/$(ls ${DOTFILES}/themes | shuf -n 1)
                CHOSEN='true'
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

###################
# Config handling #
###################

function copy-configs () {
    if [[ "${1}" = "dry" ]];
    then
        local output=$(rsync -aP --dry-run --ignore-times --exclude='themes' ${DOTFILES}/ ${HOME}/.config)
        for line in ${output};
        do 
            if [[ ! -d ${HOME}/.config/${line} ]];
            then 
                echo ${line}
            fi
        done 
    elif [[ "${1}" = "silent" ]];
    then 
        cp ${DOTFILES}/kitty/kitty.conf ${HOME}/.config/kitty/kitty.conf
    else
        rsync -aP --ignore-times --exclude='themes' ${DOTFILES}/ ${HOME}/.config
    fi
}

############################
# Color and image handling #
############################

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

    if [[ "${2}" = 'centered' ]];
    then 
        local spacer=$(printf "%.0f" $(bc -l <<< "( ${COLS} / 2 ) - (20 / 2) "))
    else 
        local spacer="8"
    fi

    for i in $(seq 0 15);
    do
        printf "\033]4;${i};${COLORS[color${i}]}\007" > ${output}
        printf "%${spacer}s %10s %5b\n" "COLOR${i}:" ${COLORS[color${i}]} "\e[38;5;${i}m$(repeat 10 "\u2588")\e[0m" 
    done
}

function substitute-params () {

    SUBFILES=$(copy-configs 'dry')

    for i in ${SUBFILES};
    do  
        if [[ -f ${HOME}/.config/${i} ]];
        then 
            for j in "${!COLORS[@]}"
            do
                sed -i "s/\$${j}/${COLORS[${j}]}/g" ${HOME}/.config/${i}
            done

            # Substitute in background path
            check-bg-ext
            sed -i "s#\$backgroundimage#${THEME}/background.${EXT}#g" ${HOME}/.config/${i}
        fi
    done 
}

function check-bg-ext () {
    if [[ -f ${THEME}/background.jpg ]];
    then 
        EXT='jpg'
    else 
        EXT='png'
    fi

    export EXT
}

function block-print-background () {
    cd ${THEME} 

    check-bg-ext
    timg --center -p quarter -g ${COLS}x${LINES} ${THEME}/background.${EXT}
}

function print-fzf-summary () {
    THEME=${DOTFILES}/themes/${1}
    LINES=$(tput lines)
    COLS=$(tput cols)

    source-colors
    print-colors ${TTY} 'centered'
    echo ''
    block-print-background
    copy-configs 'silent'
    substitute-params
    reload-term
}

####################
# Reload utilities #
####################

function reload-term () {
    kill -10 $(pidof kitty)
}

function reload-sway () {
    swaymsg 'reload' 
}

function cleanup () {
    if [[ -f /tmp/kitty.tmp && "${CHOSEN}" != 'true' ]];
    then 
        cp /tmp/kitty.tmp ${HOME}/.config/kitty/kitty.conf
    fi

    rm /tmp/kitty.tmp
    reload-term
}

#################
# Run utilities #
#################

function dry-run () {
    print-header 'Basics:'
    printf "%5s %10s" 'THEME:' ${THEME}
    echo ''

    print-header 'Copied files:'
    copy-configs 'dry'

    print-header 'Colors:'
    print-colors 

    print-header 'Background'
    block-print-background

    echo ''
}

function main () {
    initialize-args "$@"
    parse-args "$@"
    check-args
    check-dependencies

    source-colors

    if [[ ${DRYRUN} == 'true' ]];
    then 
        dry-run 
        exit 1
    fi

    print-header 'Copying configs'
    copy-configs

    print-header 'Substituting colors'
    substitute-params

    print-header 'Reloading configs'
    reload-term 
    reload-sway
}

export -f print-header 
export -f repeat 
export -f check-dependencies
export -f script-usage 
export -f initialize-args 
export -f parse-args 
export -f check-args 
export -f copy-configs 
export -f source-colors 
export -f print-colors 
export -f substitute-params 
export -f block-print-background 
export -f print-fzf-summary 
export -f dry-run
export -f reload-term
export -f check-bg-ext

main "$@"


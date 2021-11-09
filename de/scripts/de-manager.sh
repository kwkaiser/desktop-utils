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
    if [[ ! $(command -v fzf) || ! $(command -v timg) ]];
    then 
        echo 'This script expects three dependencies:'
        echo '  -fzf'
        echo '  -timg'
        exit 1
    fi 
}

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
    -s | --sub-only     Only transfer configurations with color substitutions
EOF
}

################
# Arg handling #
################

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
                    echo 'Conflicting theme selection options'
                    exit 1
                fi

                shift
                ;;

            -i | --interactive) 
                if [[ -z ${THEME} ]];
                then
                    THEME=${DOTFILES}/themes/$(ls ${DOTFILES}/themes | fzf --ansi --preview 'print-fzf-summary {}')
                    CHOSEN='true'
                else
                    echo 'Conflicting theme selection options'
                    exit 1
                fi
                
                ;; 

            -r | --random)
                if [[ -z ${THEME} ]];
                then
                    THEME=${DOTFILES}/themes/$(ls ${DOTFILES}/themes | shuf -n 1)
                    CHOSEN='true'   
                else
                    echo 'Conflicting theme selection options'
                    exit 1
                fi
                
                ;;

            -d | --dry)
                DRYRUN='true'
                ;;

            -s | --sub-only)
                SUBARG='sub-only'
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

function copy-config () {
    local dirname=$(basename $(dirname ${1}))
    local cleanname=$(echo $(basename ${1}) | sed --expression='s/sub-//g')
    mkdir -p ${HOME}/.config/${dirname}

    if [[ $(echo "$@" | grep -i 'run-dry' ) ]];
    then 
        echo ${HOME}/.config/${dirname}/${cleanname}
    else 
        cp ${1} ${HOME}/.config/${dirname}/${cleanname}
    fi
}

function copy-configs () {
    if [[ $(echo "$@" | grep -i 'run-dry') ]];
    then 
        local dryarg='run-dry'
    fi

    if [[ $(echo "$@" | grep -i 'sub-only') ]];
    then 
        echo $(find ${DOTFILES} -type f -not -path '*/themes/*' -name 'sub-*' -exec bash -c "copy-config {} ${dryarg}" \;)
    elif [[ $(echo "$@" | grep -i 'kitty') ]];
    then 
        cp ${DOTFILES}/kitty/sub-kitty.conf ${HOME}/.config/kitty/kitty.conf
        echo ${HOME}/.config/kitty/kitty.conf
    else 
        echo $(find ${DOTFILES} -type f -not -path '*/themes/*' -exec bash -c "copy-config {} ${dryarg}" \;)
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

    SUBFILES=$(copy-configs 'run-dry' 'sub-only')

    check-bg-ext

    for i in ${SUBFILES};
    do  
        if [[ -f ${i} ]];
        then 
            for j in "${!COLORS[@]}"
            do
                sed -i "s/\$${j}/${COLORS[${j}]}/g" ${i}
            done

            # Substitute in background path
            sed -i "s#\$backgroundimage#${THEME}/background.${EXT}#g" ${i}
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
    copy-configs 'kitty'
    substitute-params
    reload-term
}

####################
# Reload utilities #
####################

function reload-term () {
    kill -10 $(pidof kitty) &> /dev/null
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
    local files=$(copy-configs 'run-dry' ${SUBARG})
    for i in ${files};
    do
        echo ${i}
    done

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

    copy-configs ${SUBARG}

    substitute-params

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
export -f copy-config
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


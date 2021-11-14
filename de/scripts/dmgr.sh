#! /bin/bash

set -e
trap cleanup EXIT

######################################
# Management for desktop environment #	
######################################

#############
# Utilities #
#############

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

function get-terminal () {
    echo ''
    # printf $(ps -o comm= -p "$(($(ps -o ppid= -p "$(($(ps -o sid= -p "$$")))")))")
}

function check-dependencies () {
    if [[ ! $(command -v fzf) || ! $(command -v timg) ]];
    then 
        printf '%s\n%s\n%s\n' 'This script expects' '-    fzf' '-    timg'
        exit 1
    fi

    # Only check for kitty if there are displayed devices (e.g. handle first time setup)
    if [[ $(swaymsg -t get_outputs &> /dev/null ) && "$(get-terminal)" != 'kitty' ]];
    then 
        printf '%s\n' 'This script is only meant to work with kitty, sorry!'
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
    export TTY=$(tty)
    export DOTFILES=${HOME}/documents/desktop-utils/de/dotfiles/

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
                    THEME=$(basename $(realpath ${2-}))
                else
                    echo 'Conflicting theme selection options'
                    exit 1
                fi

                shift
                ;;

             -r | --random)
                if [[ -z ${THEME} && -d ${DOTFILES} ]];
                then
                    THEME=$(get-random-theme)
                else
                    echo 'Conflicting theme selection options or unavailable dotfiles'
                    exit 1
                fi
                
                ;;

            -i | --interactive) 
                if [[ -z ${THEME} ]];
                then
                    INTERACTIVE='true'
                    THEME=$(ls ${DOTFILES}/.config/systhemes | fzf --ansi --preview 'print-fzf-summary {}')

                    if [[ -f ${HOME}/.config/kitty/kitty.conf ]];
                    then 
                        cp ${HOME}/.config/kitty/kitty.conf /tmp/kitty.tmp
                    fi

                else
                    echo 'Conflicting theme selection options'
                    exit 1
                fi
                
                ;; 

            -d | --dry)
                DRYRUN='true'
                ;;

            -s | --sub-only)
                SUBARG='substitutable-only'
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
        printf '%s\n%s\n'  'Invalid dotfiles directory:' ${DOTFILES}
        exit 1
    fi

    if [[ -z ${THEME} || ! -d ${DOTFILES}/.config/systhemes/${THEME} || ! -f ${DOTFILES}/.config/systhemes/${THEME}/colors.txt ]];
    then 
        printf '%s\n%s\n' 'Invalid theme directory:' ${THEME}
        exit 1
    fi
}

#################
# Color control #
#################

function source-colors () {
    cd ${DOTFILES}/.config/systhemes/${THEME}
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

function check-bg-ext () {
    if [[ -f ${DOTFILES}/.config/systhemes/${THEME}/background.jpg ]];
    then 
        EXT='jpg'
    else 
        EXT='png'
    fi

    export EXT
}

##################
# Config copying #
##################

function get-random-theme () {
    printf $(ls ${DOTFILES}/.config/systhemes | shuf -n 1)
}

function get-dot-paths () {
    local mode=${1:-'all'}

    if [[ "${mode}" == 'all' ]];
    then 
        local argstring='*'
    elif [[ "${mode}" == 'substitutable-only' ]];
    then 
        local argstring='sub-*'
    fi

    printf '%s\n' $(find ${DOTFILES} -type f -not -path '*/systhemes/*' -name "${argstring}" -exec printf '%s ' {} \;)
}

function copy-dot-to-config () {
    # Expects dirty (dotfiles) path

    local nextdir=$(dirname ${1})
    local relative=$(basename ${nextdir})
    while [[ "$(realpath ${nextdir})" != "$(realpath ${DOTFILES})" ]];
    do
        nextdir=$(dirname ${nextdir})
        relative=$(basename ${nextdir})/${relative}
    done

    local dirname=$(basename $(dirname ${1}))
    local cleanname=$(echo $(basename ${1}) | sed --expression='s/sub-//g')

    if [[ "${relative}" == 'dotfiles' ]];
    then 
        relative=$(realpath ${HOME}/${cleanname})
    else 
        # Cut 'dotfiles' from name
        relative=${HOME}/$(echo ${relative} | cut -c10-)/${cleanname}
    fi

    mkdir -p $(dirname ${relative})
    cp ${1} ${relative}
    echo ${relative}
}

function substitute-params () {
    # Expects clean (~/.config) path

    check-bg-ext

    for j in "${!COLORS[@]}"
    do
        sed -i "s/\$${j}/${COLORS[${j}]}/g" ${1}
    done

    # Substitute in background path
    sed -i "s#\$backgroundimage#${DOTFILES}/.config/systhemes/${THEME}/background.${EXT}#g" ${1}
}

function cleanup () {
    if [[ "${INTERACTIVE}" == 'true' && "${APPLIED}" != 'true' ]];
    then 
        cp /tmp/kitty.tmp ${HOME}/.config/kitty/kitty.conf
        rm /tmp/kitty.tmp
        reload-term
    fi
}


########################
# Output functionality #
########################

function block-print-background () {
    cd ${DOTFILES}/.config/systhemes/${THEME} 

    check-bg-ext
    timg --center -p quarter -g $(tput cols)x$(tput lines) ${DOTFILES}/.config/systhemes/${THEME}/background.${EXT}
}

function print-colors () {
    local output=${1:-/dev/stdout}

    for i in $(seq 0 15);
    do
        printf "\033]4;${i};${COLORS[color${i}]}\007" > ${output}
        print-centered "$(printf "%${spacer}s %10s %5b\n" "COLOR${i}:" ${COLORS[color${i}]} "\e[38;5;${i}m$(repeat-char 10 "\u2588")\e[0m")"
    done
}

function print-fzf-summary () {
    THEME=${1} 
    source-colors
    print-colors ${TTY} 
    echo ''
    block-print-background
    local kittypath=$(copy-dot-to-config "${DOTFILES}/.config/kitty/sub-kitty.conf")
    substitute-params ${kittypath}
    reload-term
}

########################
# Reload functionality #
########################

function reload-term () {
    kill -10 $(pidof kitty) &> /dev/null
}

function reload-sway () {
    swaymsg 'reload' 
} 

######################
# Main functionality #
######################

function main () {
    initialize-args
    parse-args "$@"
    check-args
    check-dependencies

    # copy-dot-to-config '/home/kwkaiser/documents/desktop-utils/de/dotfiles/.config/gammastep/config.ini'
    # copy-dot-to-config '/home/kwkaiser/documents/desktop-utils/de/dotfiles/.gnupg/gpg-agent.conf'
    # copy-dot-to-config '/home/kwkaiser/documents/desktop-utils/de/dotfiles/.bashrc'

    if [[ "${DRYRUN}" == 'true' ]];
    then 
        local tocopy=$(get-dot-paths ${SUBARG})

        print-centered "$(print-header 'Basics')"
        echo ''
        printf '%s: %s\n' 'THEME' ${THEME}

        print-centered "$(print-header 'Files to transfer')"
        echo ''
        for i in ${tocopy};
        do
            printf '%s\n' ${i}
        done;

        print-centered "$(print-header 'Generated colors')"
        echo ''
        source-colors 
        print-colors
        echo ''

        print-centered "$(print-header 'Applied background')"
        echo ''
        block-print-background

    else 
        source-colors
        local tocopy=$(get-dot-paths ${SUBARG})
        for i in ${tocopy};
        do
            local cleanpath=$(copy-dot-to-config "${i}")
            substitute-params ${cleanpath}
        done;

        reload-term
        reload-sway

        APPLIED='true'
    fi
}

export -f center
export -f check-args
export -f parse-args
export -f repeat-char
export -f reload-term
export -f print-colors
export -f get-terminal
export -f source-colors
export -f print-header
export -f check-bg-ext
export -f print-centered
export -f initialize-args
export -f get-random-theme
export -f print-fzf-summary
export -f substitute-params
export -f copy-dot-to-config
export -f check-dependencies
export -f block-print-background

main "$@"
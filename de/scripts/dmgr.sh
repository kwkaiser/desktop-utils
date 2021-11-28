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

function check-dependencies () {
    if [[ ! $(command -v fzf) || ! $(command -v timg) || ! $(command -v xsettingsd) || ! $(command -v fc-list) || ! $(command -v fc-match) ]];
    then 
        printf '%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n' 'This script expects:' '- fzf' '- timg' '- xsettingsd' '- fontconfig'
        exit 1
    fi 
}

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help         Print this output
    -u | --utils        Override desktop utils path (~/documents/desktop-utils)

    -p | --pallette     Select a color pallette (default: currently applied, or random. 'i' for interactive, 'r' for random, otherwise provide relative path)
    -b | --background   Select a background     (default: currently applied, or random. 'i' for interactive, 'r' for random, otherwise provide relative path)
    -f | --font         Select a font           (default: currently applied, or random. 'i' for interactive, 'r' for random, otherwise provide relative path)

    -d | --dry          Print out variables but do not apply them
    -s | --sub-only     Only transfer configurations with substituted variables
EOF
}

#################
# Color control #
#################

function source-colors () {
    # params:
    #   - ${1}: relative path of color pallette (defaults to global pallette)

    cd ${RESC}/pallettes
    source  ./${1:-"${PALLETTE}"}

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

##################
# Config copying #
##################

function copy-resources () {
    mkdir -p ${HOME}/.fonts
    mkdir -p ${HOME}/.themes

    for i in $(ls ${RESC}/fonts);
    do 
        if [[ ! -f ${HOME}/.fonts/${i} ]];
        then 
            cp ${RESC}/fonts/${i} ${HOME}/.fonts/${i}
        fi
    done

    for i in $(ls ${RESC}/themes);
    do 
        if [[ ! -f ${HOME}/.themes/${i} && ! -d ${HOME}/.themes/${i} ]];
        then 
            cp -r ${RESC}/themes/${i} ${HOME}/.themes/${i}
        fi
    done
}

function get-random-pallette () {
    printf $(ls ${RESC}/pallettes| shuf -n 1)
}

function get-random-background () {
    printf $(ls ${RESC}/images/backgrounds | shuf -n 1)
}

function get-random-font () {
    local fonts=$(ls ${RESC}/fonts)
    local selected=$(fc-list :mono family | shuf -n 1)

    printf ${selected}
}

function kitty-backup () {
    export INTERACTIVE='true'

    if [[ -f ${HOME}/.config/kitty/kitty.conf ]];
    then 
        if [[ ! -f /tmp/kitty.tmp ]];
        then 
            cp ${HOME}/.config/kitty/kitty.conf /tmp/kitty.tmp
        fi
    fi
}

function get-dot-paths () {
    # params:
    #   - ${1}: dot path selection mode (defaults to selecting all)

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
    # params:
    #   - ${1}: explicit (realpath) of a given dotfile (pre-transfer)

    local nextdir=$(dirname ${1})
    local relative=$(basename ${nextdir})
    while [[ "$(realpath ${nextdir})" != "$(realpath ${DOTFILES})" ]];
    do
        nextdir=$(dirname ${nextdir})
        relative=$(basename ${nextdir})/${relative}
    done

    local dirname=$(basename $(dirname ${1}))
    local cleanname=$(printf $(basename ${1}) | sed --expression='s/sub-//g')

    if [[ "${relative}" == 'dotfiles' ]];
    then 
        relative=$(realpath ${HOME}/${cleanname})
    else 
        # Cut 'dotfiles' from name
        relative=${HOME}/$(printf ${relative} | cut -c10-)/${cleanname}
    fi

    mkdir -p $(dirname ${relative})
    cp ${1} ${relative}
    printf ${relative}
}

function substitute-params () {
    # params:
    #   - ${1}: explicit (realpath) of a given dotfile (post-transfer)

    for j in "${!COLORS[@]}"
    do
        sed -i "s/\$${j}/${COLORS[${j}]}/g" ${1}
    done

    # Substitute in background absolute path
    sed -i "s#\$backgroundimage#${RESC}/images/backgrounds/${BACKGROUND}#g" ${1}

    sed -i "s#\$font#${FONT}#g" ${1}
    sed -i "s#\$pallette#${PALLETTE}#g" ${1}
    sed -i "s#\$relativebackground#${BACKGROUND}#g" ${1}
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

function preview-pallette () {
    source-colors 

    local output=${1:-/dev/stdout}

    for i in $(seq 0 15);
    do
        printf "\033]4;${i};${COLORS[color${i}]}\007" > ${output}
        print-centered "$(printf "%${spacer}s %10s %5b\n" "COLOR${i}:" ${COLORS[color${i}]} "\e[38;5;${i}m$(repeat-char 10 "\u2588")\e[0m")"
    done
}

function preview-background () {
    cd ${RESC}/images/backgrounds 
    timg --center -p quarter -g $(tput cols)x$(tput lines) ./${BACKGROUND}
}

function interactive-selection () {
    if [[ "${2}" == 'pallette' ]];
    then 
        PALLETTE=${1}
    elif [[ "${2}" == 'background' ]];
    then 
        BACKGROUND=${1}
    elif [[ "${2}" == 'font' ]];
    then
        FONT=${1}
    else
        printf 'Interactive selection requires a mode'
        exit 1
    fi

    print-centered "$(print-header "Selecting ${2}")"

    source-colors
    print-centered "FONT: ${FONT}"
    preview-pallette ${TTY}
    print-centered "$(repeat-char 17 '-')" 
    preview-background

    # Update kitty
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

function reload-gtk () {
    local tmp=$(mktemp)
    printf 'Net/ThemeName "flatcolor"' >> ${tmp}
    timeout 1.0s xsettingsd -c ${tmp}  &> /dev/null
    rm ${tmp}
}

################
# Arg handling #
################

function initialize-args () { 

    export TTY=$(tty)
    export UTILS=${HOME}/documents/desktop-utils
    export RESC=${UTILS}/de/resources
    export DOTFILES=${UTILS}/de/dotfiles

    # Attempt to source background, font, and pallette
    source ~/.bashrc

    # If they fail, assign at random
    if [[ -z ${PALLETTE} ]];
    then 
        export PALLETTE=$(get-random-pallette)
    fi

    if [[ -z ${BACKGROUND} ]];
    then 
        export BACKGROUND=$(get-random-background)
    fi

    if [[ -z ${FONT} ]];
    then 
        export FONT=$(get-random-font)
    fi

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

            -u | --utils)
                UTILS=${2-}
                shift 
                ;;


            -p | --pallette)
                if [[ "${2-}" == 'r' ]];
                then 
                    PALLETTE=$(get-random-pallette)
                elif [[ "${2-}" == 'i' ]];
                then 
                    kitty-backup
                    PALLETTE=$(ls ${RESC}/pallettes | fzf --ansi --preview 'interactive-selection {} pallette')
                elif [[ ! -z "${2-}" ]];
                then
                    PALLETTE=${2-}
                else 
                    echo ''
                    # Hope to load previous pallette from ~/.bashrc
                fi

                shift
                ;;

            -b | --background)
                if [[ "${2-}" == 'r' ]];
                then 
                    BACKGROUND=$(get-random-background)
                elif [[ "${2-}" == 'i' ]];
                then 
                    kitty-backup
                    BACKGROUND=$(ls ${RESC}/images/backgrounds | fzf --ansi --preview 'interactive-selection {} background')
                elif [[ ! -z "${2-}" ]];
                then
                    BACKGROUND=${2-}
                else 
                    echo ''
                    # Hope to load previous background from ~/.bashrc
                fi

                shift
                ;;

            -f | --font)
                if [[ "${2-}" == 'r' ]];
                then 
                    FONT=$(get-random-font)
                elif [[ "${2-}" == 'i' ]];
                then
                    kitty-backup
                    FONT=$(fc-list :mono family | fzf --ansi --preview 'interactive-selection {} font')
                    
                elif [[ ! -z "${2-}" ]];
                then
                    FONT=$(fc-match : family "${2-}" )
                else 
                    echo ''
                    # Hope to load previous font from ~/.bashrc
                fi

                shift
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
    if [[ -z ${PALLETTE} || ! -f ${RESC}/pallettes/${PALLETTE} ]];
    then 
        printf "No such pallette: ${PALLETTE}\n"
        exit 1
    fi

    if [[ -z ${BACKGROUND} || ! -f ${RESC}/images/backgrounds/${BACKGROUND} ]];
    then 
        printf "No such background: ${BACKGROUND}\n"
        exit 1
    fi

    if [[ -z ${FONT} || ! $(fc-list : family | grep -i "${FONT}" ) ]];
    then 
        printf "No such font: ${FONT}\n"
        exit 1
    fi
}

######################
# Main functionality #
######################

function main () {
    initialize-args
    copy-resources
    check-dependencies 
    parse-args "$@"
    check-args

    if [[ "${DRYRUN}" == 'true' ]];
    then 
        local tocopy=$(get-dot-paths ${SUBARG})

        print-centered "$(print-header 'Basics')"
        printf '\n'
        print-centered "$(printf '%s: %s\n' 'FONT' ${FONT})"
        print-centered "$(printf '%s: %s\n' 'PALLETTE' ${PALLETTE})"
        print-centered "$(printf '%s: %s\n' 'BACKGROUND' ${BACKGROUND})"
        printf '\n'

        print-centered "$(print-header 'Files to transfer')"
        printf '\n'
        for i in ${tocopy};
        do
            printf '%s\n' ${i}
        done;

        print-centered "$(print-header 'Generated colors')"
        printf '\n'
        source-colors 
        preview-pallette
        printf '\n'

        print-centered "$(print-header 'Applied background')"
        printf '\n'
        preview-background

    else
        source-colors
        local tocopy=$(get-dot-paths ${SUBARG})
        for i in ${tocopy};
        do
            local cleanpath=$(copy-dot-to-config "${i}")
            substitute-params ${cleanpath}
        done;

        export APPLIED='true'

        reload-term
        reload-sway
        reload-gtk
    fi
}

export -f cleanup
export -f center
export -f check-args
export -f parse-args
export -f repeat-char
export -f reload-term
export -f print-header
export -f print-centered

export -f source-colors
export -f preview-pallette
export -f preview-background
export -f interactive-selection

export -f substitute-params
export -f copy-dot-to-config


main "$@"
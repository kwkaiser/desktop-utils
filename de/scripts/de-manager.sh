
#! /bin/bash

set -e

######################################
# Management for desktop environment #	
######################################

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help     Print this output
    -b | --browse   Select a desktop environment theme through ranger browsing
    -t | --theme    Provide a specific path to an environment theme and setup
    -m | --mode     Override mode (default: 'desktop')
    -d | --dry      Print out variables, but do not appy theme
EOF
}

function check-dependencies () {
    if [[ ! $(check-installed pip) -eq 0 || ! $(check-installed ranger) -eq 0 || ! $(check-installed rsync) -eq 0 ]];
    then 
        echo "This script requires:"
        echo "  - ranger"
        echo "  - pip (with pillow installed, locally"
        echo "  - rsync"
        exit 1
    fi
}

function initialize-args () {
    MODE='desktop'
    CURRENTDIR=$(dirname $(realpath $0))
    DOTFILES=$(realpath ${CURRENTDIR}/../dotfiles)

    cd ${CURRENTDIR}
    source "./utils.sh"
}


function parse-args () {
        while :; do
        case "${1-}" in
            -h | --help) 
                script-usage 
                exit 1
                ;;

            -t | --theme)

                if [[ -z ${THEMEPATH} ]];
                then
                    THEMEPATH=${2-}

                    if [[ ! -d ${THEMEPATH} ]];
                    then 
                        echo 'Invalid theme path provided'
                        echo "Themes are current stored under ${DOTFILES}/themes"
                        exit 1
                    fi
                else
                    echo "Conflicting theme selection options"
                    exit 1
                fi

                shift
                ;;

            -b | --browse) 

                if [[ -z ${THEMEPATH} ]];
                then 
                    browse-themes
                else 
                    echo "Conflicting theme selection options"
                    exit 1
                fi
                ;;

            -m | --mode)
                case ${2-} in 
                    'laptop'|'desktop'|'virtual')
                        MODE=${2-}
                        shift
                        ;;

                    *)
                        echo 'Invalid mode; specify either laptop, dekstop, or virtual machine'
                        exit 1
                        ;;
                esac
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

function browse-themes () {
    cd ${DOTFILES}

    TMPDIR=$(mktemp --dir)

    for i in $(find . -maxdepth 2 -type d -name "*${MODE}");
    do 
        i=$(realpath ${i})
        SHOWCASENAME="$(basename $(dirname ${i})).jpg"

        ln -sf ${i}/meta/showcase.jpg ${TMPDIR}/${SHOWCASENAME}
    done

    TMPFILE=$(mktemp)

    ranger ${TMPDIR} --choosefile=${TMPFILE} 1>&2

    FILE=$(cat ${TMPFILE})
    THEMEPATH=${DOTFILES}/$(echo "$(basename ${FILE})" | cut -f 1 -d '.')/${MODE}

    rm -rf ${TMPDIR}
    rm ${TMPFILE}
}

function source-colors () {
    cd ${THEMEPATH}/meta
    source ./colors.txt

    declare -g -A COLORS
    COLORS['bg']=$background
    COLORS['foreground']=$foreground
    COLORS['cursorColor']=$foreground
    COLORS['color1']=$color1
    COLORS['color2']=$color2
    COLORS['color3']=$color3
    COLORS['color4']=$color4
    COLORS['color5']=$color5
    COLORS['color6']=$color6
    COLORS['color7']=$color7
    COLORS['color8']=$color8
    COLORS['color9']=$color9
    COLORS['color10']=$color10
    COLORS['color11']=$color11
    COLORS['color12']=$color12
    COLORS['color13']=$color13
    COLORS['color14']=$color14
    COLORS['color15']=$color15

    export COLORS

    cd ${CURRENTDIR}
}

function copy-configs () {
    rsync -aP --exclude="meta" --ignore-times ${THEMEPATH} ${HOME}/.config
}

function substitute-colors () {
    SUBFILES=$(rsync -aP --dry-run --ignore-times --exclude="meta" ${THEMEPATH} ${HOME}/.config | tail -n +2)

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

function dry-run () {
    print-header 'Basics:'
    printf "%15s %15s" 'THEMEPATH:' ${THEMEPATH}
    echo ''

    print-header 'Copied files:'

    rsync -aP --dry-run --exclude="meta" --ignore-times ${THEMEPATH} ${HOME}/.config/

    print-header 'Colors:'
    for i in $(seq 1 15);
    do
        printf "\033]4;${i};${COLORS[color${i}]}\007"
        printf "%15s %10s %5b\n" "COLOR${i}:" ${COLORS[color${i}]} "\e[38;5;${i}m$(repeat 10 "\u2588")\e[0m" 
    done

    echo ''
}


function main () {
    initialize-args "$@"
    check-dependencies
    parse-args "$@"

    if [[ -z ${THEMEPATH} ]];
    then 
        echo 'No theme path provided'
        exit 1
    fi

    source-colors

    if [[ ${DRYRUN} == 'true' ]];
    then 
        dry-run 
        exit 1
    fi

    copy-configs
    substitute-colors
}

main "$@"
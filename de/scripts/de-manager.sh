
#! /bin/bash

######################################
# Management for desktop environment #	
######################################

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help     Print this output
    -t | --theme    Provide path to specific theme group
    -r | --random   Select random theme from available theme groups
    -d | --dry      Print out variables, but do not apply them
EOF
}

function initialize-args () {
    CURRENTDIR=$(dirname $(realpath $0))
    DOTFILESDIR=$(realpath ${CURRENTDIR}/../dotfiles)

    # Configs and where they belong
    declare -g -A CONFIGS
    CONFIGS['sway/config']=${HOME}/.config/sway/config

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
                THEMEPATH=${2-}

                if [[ ! -d ${THEMEPATH} ]];
                then 
                    echo 'Invalid theme path provided'
                    echo "Themes are current stored under ${DOTFILESDIR}/color-collections"
                    exit 1
                fi

                shift
                ;;

            -r | --random)
                cd ${DOTFILESDIR}
                THEMEPATH=${DOTFILESDIR}/color-collections/$(ls color-collections | shuf -n 1)
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

function source-colors () {
    cd ${THEMEPATH}
    source ./colors

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
    for i in "${!CONFIGS[@]}"
    do
        if [[ ! -d $(dirname ${CONFIGS[$i]}) ]];
        then 
            mkdir -p $(dirname ${CONFIGS[$i]})
        fi

        cp -r ${DOTFILESDIR}/${i} ${CONFIGS[$i]}
    done 
}

function substitute-colors () {
    for i in "${!CONFIGS[@]}"
    do
        for j in "${!COLORS[@]}"
        do
            sed -i "s/${j}/${COLORS[${j}]}/g" ${CONFIGS[${i}]}
        done
    done 
}

function dry-run () {
    print-header 'Script configs and locations:'

    printf "%15s    %15s\n" 'THEMEPATH:' ${THEMEPATH}
    for i in "${!CONFIGS[@]}"
    do
        printf "%15s    %15s\n" "${i}:" ${CONFIGS[$i]}
    done

    print-header 'Colors:'
    for i in "${!COLORS[@]}"
    do
        printf "%15s %10s\n" "$(echo $i | tr [a-z] [A-Z]):" ${COLORS[$i]}
    done

}

function main () {
    initialize-args "$@"
    parse-args "$@"

    if [[ ! -z ${THEMEPATH} ]];
    then 
        source-colors 

        if [[ ${DRYRUN} != 'true' ]];
        then 
            copy-configs
            substitute-colors
        fi
    fi

    if [[ ${DRYRUN} == 'true' ]];
    then 
        dry-run
    fi
}

main "$@"
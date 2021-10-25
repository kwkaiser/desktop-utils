
#! /bin/bash

######################################
# Management for desktop environment #	
######################################

function script-usage () {
    cat << EOF

Script for managing desktop environment
Usage:
    -h | --help     Print this output
    -b | --browse   Select a theme through ranger browsing
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

                if [[ -z ${THEMEPATH} ]];
                then
                    THEMEPATH=${2-}

                    if [[ ! -d ${THEMEPATH} ]];
                    then 
                        echo 'Invalid theme path provided'
                        echo "Themes are current stored under ${DOTFILESDIR}/themes"
                        exit 1
                    fi
                else
                    echo "Conflicting theme selection options"
                    exit 1
                fi

                shift
                ;;

            -r | --random)

                if [[ -z ${THEMEPATH} ]];
                then 
                    get-random-theme 
                else
                    echo "Conflicting theme selection options"
                    exit 1
                fi
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

function get-random-theme () {
    cd ${DOTFILESDIR}
    THEMEPATH=${DOTFILESDIR}/themes/$(ls themes | shuf -n 1)
}

function browse-themes () {
    if [[ ! $(check-installed ranger) -eq 0 || ! $(check-installed w3m) -eq 0  ]];
    then 
        echo "Browsing themes not available without ranger, w3m"
        echo "To enable browsing functionality, install deps & ensure image preview is set in ~/.config/ranger/rc.conf"
        exit 1
    fi

    cd ${DOTFILESDIR}/themes
    TMP=$(mktemp --dir)

    for i in $(find . -type f -name '*.jpg' -o -name "*.png" ); 
    do
        FILE=$(realpath ${i})
        cp ${FILE} ${TMP}/$(basename $(dirname ${FILE})).$(echo "${FILE#*.}")
    done

    TMP2=$(mktemp)

    ranger ${TMP} --choosefile=${TMP2} 1>&2

    if [[ -d $(cat ${TMP2}) ]];
    then 
        echo "Must select a background file"
        exit 1
    fi

    THEMEPATH=${DOTFILESDIR}/themes/$(basename $(cat ${TMP2}) )
    THEMEPATH=$(echo "${THEMEPATH%%.*}")

    rm -rf ${TMP}
    rm ${TMP2}

    cd ${CURRENTDIR}
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

        if [[ ${DRYRUN} == 'true' ]];
        then 
            dry-run
            exit 0
        fi
    else
        echo "No theme path provided"
        exit 1
    fi
}

main "$@"
#! /bin/bash

function parse-args () {
        while :; do
        case "${1-}" in
            -h | --help) 
                script-usage 
                exit 1
                ;;

            -s | --search)
                SEARCHING='true'
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

function script-usage () {
    cat << EOF

Script usage description 
Usage:
    journal 
    -h | --help         Print this output
    -s | --search       Search existing journal entries
EOF

    exit 1
}

function main () {
    parse-args "$@"

    if [[ "${SEARCHING}" == 'true' ]];
    then 
        local entry=$(
            for i in $(find ${HOME}/.password-store/personal/journal -type f);
            do

                local cleanname=$(basename ${i})
                local nextdir=$(dirname ${i})
                local relative=$(basename ${nextdir})

                while [[ "$(realpath ${nextdir})" != "${HOME}/.password-store/personal/journal" ]];
                do
                    nextdir=$(dirname ${nextdir})
                    relative=$(basename ${nextdir})/${relative}
                done

                local truename=$(printf ${relative} | cut -c10-)/${cleanname} 

                echo "${truename%.*}"
            done | fzf 
        )

        if [[ -z ${entry} ]];
        then 
            printf 'No journal entry selected\n'
            exit 1
        fi

        pass edit personal/journal/${entry}
    else
        pass edit personal/journal/$(date +"%Y-%m-%d")
    fi
}

main "$@"
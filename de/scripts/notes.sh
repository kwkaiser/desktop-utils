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

function script-usage-() {
    cat << EOF

Script usage description 
Usage:
    -h | --help         Print this output
    -s | --search       Search existing recipes
EOF

    exit 1
}

function main () {
    parse-args "$@"

    if [[ "${SEARCHING}" == 'true' ]];
    then 
        local note=$(
            for i in $(find ${HOME}/.password-store/personal/notes -type f);
            do

                local cleanname=$(basename ${i})
                local nextdir=$(dirname ${i})
                local relative=$(basename ${nextdir})

                while [[ "$(realpath ${nextdir})" != "${HOME}/.password-store/personal/notes" ]];
                do
                    nextdir=$(dirname ${nextdir})
                    relative=$(basename ${nextdir})/${relative}
                done

                local truename=$(printf ${relative} | cut -c6-)/${cleanname} 

                echo "${truename%.*}"
            done | fzf 
        )

        if [[ -z ${note} ]];
        then 
            printf 'No note selected\n'
            exit 1
        fi

        pass edit personal/notes/${note}
    else

        if [[ -z ${1} ]];
        then 
            printf 'No note selected\n'
            exit 1
        fi

        pass edit personal/notes/${1}
    fi
}

main "$@"
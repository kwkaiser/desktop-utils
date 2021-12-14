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
                local test='test'
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
        local recipe=$(
            for i in $(ls ${HOME}/.password-store/personal/notes/recipes);
            do
                echo "${i%.*}"
            done | fzf 
        )

        pass edit personal/notes/recipes/${recipe}

    else
        pass edit personal/notes/recipes/${1}
    fi
}

main "$@"
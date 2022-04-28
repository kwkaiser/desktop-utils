#! /bin/bash

function parse-args () {
        while :; do
        case "${1-}" in
            -h | --help) 
                script-usage 
                exit 1
                ;;

            -n | --notes)
                NOTES=${2-}
                shift 
                ;;

            -s | --search)
                SEARCHING='true'
                ;;

            -f | --file)
                ADDFILE='true'
                FILE=${2-}
                ;;

            -r | --remove-note)
                REMOVE='true'
                REMOVEDNOTE=${2-}
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

function initialize-args () {
    NOTES=${HOME}/.password-store/personal/notes
    RECIPIENT='karl@kwkaiser.io'
}

function script-usage () {
    cat << EOF

Script usage description 
Usage:
    notes [note name]
    -h | --help         Print this output
    -n | --notes        Default note location (~/.password-store/personal/notes)
    -s | --search       Search existing recipes
    -f | --file         Add & encrypt image
    -r | --remove-note  Remove an image
EOF

    exit 1
}

function main () {
    initialize-args
    parse-args "$@"

    if [[ "${SEARCHING}" == 'true' ]];
    then 
        local note=$(
            for i in $(find ${NOTES} -type f);
            do
                local cleanname=$(basename ${i})
                local nextdir=$(dirname ${i})
                local relative=$(basename ${nextdir})

                while [[ "$(realpath ${nextdir})" != ${NOTES} ]];
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

    elif [[ "${ADDFILE}" == 'true' ]];
    then 
        if [[ -z ${FILE} ]];
        then
           printf "No file selected\n"
           exit 1
        fi

        mkdir -p ${NOTES}/assets

        gpg --encrypt --recipient ${RECIPIENT} -o ${NOTES}/assets/$(basename ${FILE}).gpg ${FILE}
        pass git add ${NOTES}/assets/$(basename ${FILE}).gpg
        pass git commit -m "Added new file: ${FILE}"

    elif [[ "${REMOVE}" == 'true' ]];
    then 
        if [[ -z ${REMOVEDNOTE} ]];
        then
           printf "No note / image selected\n"
           exit 1
        fi
        pass rm personal/notes/assets/${REMOVEDNOTE} 

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
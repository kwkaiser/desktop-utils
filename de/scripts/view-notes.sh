#! /bin/bash

set -e

function script-usage () {
    cat << EOF

Script for viewing encrypted notes
Usage:
    -h | --help             Print this output
    -u | --utils            Override desktop utils path (~/documents/desktop-utils)
    -n | --notes            Override notes path (~/.password-store/personal/notes)

EOF
}

function initialize-args () { 
    UTILS=${HOME}/documents/desktop-utils
    NOTES=${HOME}/.password-store/personal/notes
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

            -n | --notes)
                NOTES=${2-}
                shift 
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

function main () {
    initialize-args 
    parse-args "$@"

    cp -r ${NOTES} ${TEMP_DIR}
    find ${TEMP_DIR} -name "*.gpg" -exec gpg --decrypt-files --quiet {} \+ 
    find ${TEMP_DIR} -name "*.gpg" -exec rm -rf {} \+ 
    chmod -R 770 ${TEMP_DIR}
    find ${TEMP_DIR} -type f -not -name '*.png' -not -name '*.jpg' -not -name '*.pdf' | xargs -P 0 -I % /bin/bash -c "pandoc --from=markdown --to=html -o % %"

    # Add links to css
    cp ${UTILS}/de/resources/misc/notes.css ${TEMP_DIR}/notes.css
    css_link="<link rel='stylesheet' type='text/css' href='${TEMP_DIR}/notes.css'/>"

    local css_temp=$(mktemp)
    echo -e ${css_link} > ${css_temp}

    find ${TEMP_DIR} -type f | xargs -P 0 -I % /bin/bash -c "cat ${css_temp} >> %"

    while true;
    do
        local new_tab=$(find ${TEMP_DIR} -type f | cut -c $(( ${#TEMP_DIR} + 8 ))- | fzf)

        if [[ -z ${new_tab} ]];
        then
            echo "Exiting.." 
            exit 1
        else
            firefox -new-tab -url "file://${TEMP_DIR}/notes/${new_tab}"
        fi
    done
}

TEMP_DIR=$(mktemp --directory)
function clear_data () {
    rm -rf ${TEMP_DIR}    
}
trap clear_data EXIT

main "$@"
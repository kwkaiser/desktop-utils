#! /bin/bash

function check-dependencies () {
    if [[ ! $(command -v pamixer) || ! $(command -v dunst) ]];
    then 
        echo 'This script expects pamixer and dunst to run properly'
        exit 1
    fi
}


function main () {
    # params:
    #   - ${1}: 'up' or 'down' or 'mute'
    #   - ${2}: increment value (default: 5)
    #   - ${3}: notification timeout time (default: 1 second)

    check-dependencies
    local increment="${2:-5}" 
    local timeout="${3:-1000}"
    local vol=$(pamixer --get-volume)

    if [[ "${1}" == 'up' ]];
    then
        local newvol=$(echo $(( ${vol} + ${increment} )))
        local finalvol=$(echo $(( ${newvol} < 100 ? ${newvol}: 100 )) )
    elif [[ "${1}" == 'down' ]];
    then
        local newvol=$(echo $(( ${vol} - ${increment} )) )
        local finalvol=$(echo $(( ${newvol} > 0 ? ${newvol}: 0 )) )
    elif [[ "${1}" == 'mute' ]];
    then 
        if [[ "$(pamixer --get-mute)" == 'true' ]];
        then 
            pamixer -u
        else 
            pamixer -m
        fi
    fi

    if [[ "${1}" != 'mute' ]];
    then 
        pamixer --set-volume ${finalvol}
        dunstify --timeout ${timeout} --replace 100001 --appname 'Volume:' "${finalvol}"
    else

        if [[ "$(pamixer --get-mute)" == 'true' ]];
        then 
            local mutedvar='Muted'
        else 
            local mutedvar='Unmuted'
        fi

        dunstify --timeout ${timeout} --replace 100001 --appname 'Volume:' "${mutedvar}"
    fi

}

main "$@"
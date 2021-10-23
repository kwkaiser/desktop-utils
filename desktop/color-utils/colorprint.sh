#!/bin/bash

cd $(dirname $(realpath $0))

function script-usage () {
    cat << EOF
Color printing: accepts rgb or hex values and prints them in a terminal.
Note: this script sets your terminal's colors through escape sequences.
This may impact other programs; to undo the changes, restart your terminal.
Script usage:
	-h|help		Display this output
	-b|block	Display block (default: block icon, u"\u2588", multiplied by 7)
	-r|RGB		Use colors provided as rgb values (format: R G B)
	-s|show		Show the relevant hex values of colors
EOF
    exit 1
}

function initialize-args () {
	BLOCKICON="\u2588"
	USERGB='false'
	SHOW='false'
}

function parse-args () {
	ORIGINALARGS="$@"

    while getopts "hrsb:" o; do 
        case "${o}" in 
            h)
                script-usage; exit 1
                ;;
			r)
				USERGB='true'
				;;
			s)
				SHOW='true'
				;;
			b)
				BLOCKICON=${OPTARG}
				;;

			n)
				NEWLINE=${OPTARG}
				;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

function rgb-to-hex () {
	printf "#%02x%02x%02x\n" "$@"
}

main () {
	initialize-args
	parse-args "$@"

	COUNT=0
	STDIN="$(cat -)"
	COLORS=$(tput colors)

	while read LINE 
	do 
		if [[ ${USERGB} == 'true' ]];
		then
			CHANGEVAL=$(rgb-to-hex ${LINE})
		else 
			CHANGEVAL=${LINE}
		fi

		if [[ ${SHOW} == 'true' ]];
		then
			OUTPUT="$( printf "%0.s${BLOCKICON}" {0..7} ) ${COUNT} ${CHANGEVAL}"
		else
			OUTPUT="$( printf "%0.s${BLOCKICON}" {0..7} )"
		fi

		if [[ ${COUNT} -lt ${COLORS} ]];
		then
			printf "\033]4;${COUNT};${CHANGEVAL}\007"
			printf "\e[38;5;${COUNT}m${OUTPUT}\e[0m\n" 
		else
			echo "Can't show more than ${COLORS} at a time per terminal capabilities";
			exit 1
		fi

		COUNT=$((${COUNT} + 1))

	done <<< "${STDIN}"
}

main "$@"


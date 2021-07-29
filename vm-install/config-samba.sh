#! /bin/bash

source ../lib/util.sh

function script-usage () {
    cat << EOF
Usage: 
	-a [account]| Account given shared access to the VM (default: kwkaiser)
	-h          | help          Displays this dialogue	
EOF
    exit 1
}

function initialize-args () {
	CURRENTDIR=$(dirname $(realpath $0))
	ACCOUNT='kwkaiser'	
}

function parse-args () {
    ORIGINALARGS="$@"

    while getopts "a:h" o; do 
        case "${o}" in 
			a)
				ACCOUNT=${OPTARG}
				;;
			h)
				script-usage
				exit 1
				;;
            ?)
                script-usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND-1))
}

function check-root () {
	if [ ${UID} -ne 0 ];
	then 
		echo "Run as root; need to mount isos"
		exit 1
	fi
}

copy-and-substitute() {
	print-header 'Substituting config args'

	cp confs/smb.conf /etc/samba/smb.conf
	sed -i -r "s/ACCOUNT-VAR/${ACCOUNT}/g" /etc/samba/smb.conf
}

start () {
	print-header 'Restarting samba service; should be mountable under windows'

	systemctl enable smb
	systemctl restart smb
}

function main () {
    check-root
	initialize-args

	cd ${CURRENTDIR}

	parse-args "$@"
	copy-and-substitute
	start

}

main "$@"
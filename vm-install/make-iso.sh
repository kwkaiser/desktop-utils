#! /bin/bash

source ../lib/util.sh

function script-usage () {
    cat << EOF
Usage: 
	-f [path]   | file          Filepath to provided windows 10 iso
	-a [account]| account       Account name of windows 10 user                 (default: kwkaiser)
	-n [host]   | hostname      Hostname of windows 10 installation             (default: windowsvm)
	-o [path]   | output        Output location for modified windows 10 iso     (default: current dir)
	-h          | help          Displays this dialogue	
EOF
    exit 1
}

function initialize-args () {
	CURRENTDIR=$(dirname $(realpath $0))

	ACCOUNT='kwkaiser';
	HOST='windowsvm';
	OUTPUTPATH=${CURRENTDIR}/autowindows.iso
}

function parse-args () {
    ORIGINALARGS="$@"

    while getopts "f:anoh" o; do 
        case "${o}" in 
            f)
                ISOPATH=${OPTARG}
				;;
			a)
                ACCOUNT=${OPTARG}
                ;;
            n)
                HOSTNAME=${OPTARG}
                ;;
            o)  
				OUTPUTPATH=${OPTARG}
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
	if [ ${EUID} != 0 ];
	then 
		echo "Run as root; need to mount isos"
		exit 1
	fi
}

function check-deps () {
    if [[ ! $(command -v 'mkisofs') ]];
    then 
        echo "cdrkit/cdrtools required as dependency to create new isos" 
        exit 1;
    fi
}

function copy-iso () {
	print-header 'Mounting windows iso and copying contents'

	mkdir autowindows 
	
	if [[ ! -d /mnt/mountpoint ]];
	then 
		mkdir /mnt/mountpoint
	fi
	
	mount ${ISOPATH} /mnt/mountpoint -o loop
	cp -r /mnt/mountpoint/* ./autowindows/

	umount /mnt/mountpoint
}

function copy-template () {
	print-header 'Copying in autounattend template and filling values'

	cp ./confs/autounattend-template.xml ./autowindows/autounattend.xml
	sed -i -r "s/ACCOUNT-VAR/${ACCOUNT}/g" ./autowindows/autounattend.xml
}

function make-iso () {
	print-header 'Creating new windows iso'

	mkisofs -o ${OUTPUTPATH} ./autowindows
}

function clean-up () {
	print-header 'Cleaning up'

	rm -rf ./autowindows
}

function main () {
    check-root
    check-deps
	initialize-args
	parse-args "$@"

	if [ -z ${ISOPATH} ];
	then
		echo 'A filepath (-f [path]) to a windows iso is required. Use -h for help'
		exit 1;
	fi

	cd ${CURRENTDIR}
	copy-iso 
	copy-template 
	make-iso
	clean-up

}

main "$@"
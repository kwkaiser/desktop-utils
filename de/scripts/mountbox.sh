#! /bin/bash

mount -t cifs //192.168.0.69/photos /home/kwkaiser/box/photos/ -o credentials=/home/kwkaiser/.smbcredentials,uid=1000,gid=1000 0 0
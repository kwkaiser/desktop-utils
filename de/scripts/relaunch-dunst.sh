#! /bin/bash

if [[ ! -z $(pidof dunst) ]]; 
then 
    kill $(pidof dunst)

    sleep 2 
fi

dunst
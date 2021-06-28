#!/bin/bash

print-header () {
    LENGTH=${#1}

    echo ''
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ${1}
    seq -s= ${LENGTH}|tr -d '[:digit:]'
    echo ''
}

#! /bin/bash
# Gotta run this to get latexindent to work, because perl is a godforsaken language

set -e

if [[ "$EUID" -eq 0 ]];
then 
    echo "Must be run as root"
    exit 1
else 
    cpan YAML::Tiny
    cpan File::HomeDir
    cpan Unicode::GCString
fi
#!/bin/bash

#Import Lib and reset function
#source <(curl -s https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh)
#if [ "$1" = "-reset" ]; then echo "RESET"; exit 0; fi 

#if test -f ./LcLib-shell.sh; then
source ./LcLib-shell.sh
#else
#    wget https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh .
#    sudo chmod +x ./LcLib-shell.sh
#    source ./LcLib-shell.sh
#fi

echo ${REPOSITORY_SERVER}

exit 0

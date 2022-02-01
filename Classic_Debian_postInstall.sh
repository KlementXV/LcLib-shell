#!/bin/bash

LINK_LCLIB='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh'

Main() {
    source ./LcLib-shell.sh

    LcLib_update_dns 1.1.1.1 8.8.8.8 8.8.4.4
    LcLib_install_firewall iptables
    LcLib_update_firewall iptables docker
    LcLib_anssi_conf
    LcLib_update_ssh 22 clm
    LcLib_install_docker
    LcLib_install_dockerCompose

    if [ "$2" = "0" ]; then
        if [ "$1" != "-keep" ]; then rm ./LcLib-shell.sh; exit 0; fi
    fi
}

test_LcLib() {
    if test -f ./LcLib-shell.sh; then
        echo "1"
    else
        if [[ `wget -S --spider "${LINK_LCLIB}" 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
            wget https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh
            echo "0"
        fi
    fi
}

res=test_LcLib
Main $1 $res

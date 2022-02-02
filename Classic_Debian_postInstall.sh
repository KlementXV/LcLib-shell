#!/bin/bash

LINK_LCLIB='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/LcLib-shell.sh'

Main() {
    source ./LcLib-shell.sh $*
    LcLib_update_hostname "$1" "$2"
    LcLib_update_dns "1.1.1.1" "8.8.8.8" "8.8.4.4"
    LcLib_install_firewall "iptables"
    LcLib_update_firewall "iptables" "docker"
    LcLib_anssi_conf
    LcLib_update_ssh 22 "clm"
    LcLib_install_docker
    LcLib_install_dockerCompose
}

if test -f ./LcLib-shell.sh; then
    EXIST="1"
    Main $*
else
    if [[ `wget -S --spider "${LINK_LCLIB}" 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
        echo -e -ne "\033[0;35mDOWNLOAD LIBRARY - \033[0m \r"
        sudo sh -c "wget ${LINK_LCLIB} && sleep 5" 2> /dev/null
        echo -e -ne "\033[0;32mDOWNLOAD LIBRARY - DONE\033[0m \r"
        echo -ne '\n'
        EXIST="0"
        Main $1
    fi
fi
if [ "$EXIST" != "1" ] && [ "$*" =~ "-keep" ]; then rm ./LcLib-shell.sh; exit 0; fi

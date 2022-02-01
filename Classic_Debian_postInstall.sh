#!/bin/bash

source ./LcLib-shell.sh

if [ "$1" = "-reset" ]; then LcLib_reset_envVariable; exit 0; fi

#LcLib_check_Install_sudo
#LcLib_update_system
LcLib_update_dns 1.1.1.1 8.8.8.8 8.8.4.4
LcLib_install_firewall iptables
LcLib_update_firewall iptables docker
LcLib_anssi_conf
LcLib_update_ssh 22 clm
LcLib_install_docker
LcLib_install_dockerCompose

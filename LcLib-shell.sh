#!/bin/bash

# LCLib-shell.sh
# This is a shell library.
# Version 1 consists of functions to use when deploying a server.
#© 2022 Clément Levoux

#Links
LINK_UPDATE_FIREWALL_FILE='https://raw.githubusercontent.com/firewall/'
LINK_ANSSI_CONF='https://raw.githubusercontent.com/anssi_conf.sh'
LINK_SSH_KEYS='https://raw.githubusercontent.com/clementlvx/test/main/key'
LINK_SSH_CONFIG='https://raw.githubusercontent.com/clementlvx/test/main/sshd_config'
LINK_SSH_BANNER='https://raw.githubusercontent.com/clementlvx/test/main/issue.net'
LINK_DOCKER_INSTALL='https://raw.githubusercontent.com/docker/docker-install/master/install.sh'

LOG_DIR=/var/log
BLACK='\033[0;30m'
ERROR='\033[0;31m' #ERROR or REMOVE
OK='\033[0;32m' #OK
WARNING='\033[1;33m' #WARNING
INSTALL='\033[0;35m' #INSTALL
INFO='\033[0;36m' #INFO
NORMAL='\033[0m'
ScriptName=`basename "$0" .sh`

#===============================
#Init
    #ADD ENV. VAR. with prefixe "LcLib" - LcLib_export packageManager apt-get
    LcLib_export() {
        name=$1 #of Varible
        variable=$2 #Content of variable
        echo ${name}=${variable} >> .env #import var. in .env file
    }
    #Check and init which package Manager are used - LcLib_init_packageManager
    LcLib_init_packageManager() {
        if command -v apt-get >/dev/null; then #OS use APT ?
            LcLib_printer "- apt-get is used here" INFO
            LcLib_export packageManager apt-get
        elif command -v yum >/dev/null; then #OS use YUM ?
            LcLib_printer "- yum is used here" INFO
            LcLib_export packageManager yum
        else
            LcLib_printer "- I have no idea what im doing here" ERROR
            exit 0
        fi
    }
    #CHECK IF ENV. VAR. IS SET - LcLib_check_envVariable
    LcLib_check_envVariable() {
        if test -f .env; then
            source .env
            LcLib_printer "ENV file - OK" INFO
        else
            LcLib_init_envVariable #init env
        fi
    }
    #INIT ENV. VAR. - LcLib_init_envVariable
    LcLib_init_envVariable() {
        LcLib_printer "INIT ENV file" WARNING
        LcLib_init_packageManager
    }
    #Delete and init another .env
    LcLib_reset_envVariable() {
        rm -rf .env #Delete .env
        LcLib_init_envVariable #Init .env
    }

#Other
    #Command echo - LcLib_printer "Bonjour" ERROR
    LcLib_printer() {
        text=$1
        color=$2
        log=$3
        echo -e "${!color}${text}${NORMAL}"
        #if log == true { print in logfile }
    }
    LcLib_wget_testExec() {
        LINK=$1
        ACTION=$2
        DESCRIPTION=$3
        if [[ `wget -S --spider $LINK 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
            LcLib_printer $DESCRIPTION $ACTION
            wget -qO - $LINK | sudo bash
        fi
    }
    LcLib_wget_testExec() {
        for i in $*; do 
            cat "./ssh/keys/${i}"
        done
    }

#===============================
#Checks
    #Check if sudo are installed, else install it - checkInstall_sudo
    LcLib_check_Install_sudo() {
        if ! hash sudo 2>/dev/null; then
            LcLib_printer "INSTALL SUDO" INSTALL
            su -c "${packageManager} install sudo ; echo '$USER ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo"
        fi
    }

    #Check if script are run with root - check_not_superuser
    LcLib_check_not_superuser() {
        #not superuser check
        if ! [ "$EUID" -ne 0 ] ; then
            LcLib_printer "Dont run this script as root, run as the user whose environment u want to change." ERROR
            exit
        fi
    }

#Install & Update
    LcLib_update_system() {
        sudo ${packageManager} -qq update && sudo ${packageManager} -qq upgrade -y && sudo ${packageManager} -qq full-upgrade -y && sudo ${packageManager} -qq autoremove -y
    }

#SSH
    #Check if script are run with root - check_not_superuser
    LcLib_update_ssh() {
        sudo rm ~/.ssh
        sudo mkdir ~/.ssh
        sudo chmod 700 ~/.ssh
        sudo wget -qO - ${LINK_SSH_KEYS} | cat >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        sudo wget -O /etc/issue.net ${LINK_SSH_BANNER}
        sudo wget -O /etc/ssh/sshd_config ${LINK_SSH_CONFIG}
        sudo service ssh restart
    }

#DNS
    LcLib_update_dns() {
        echo nameserver 1.1.1.1 | sudo tee /etc/resolv.conf
        echo nameserver 8.8.8.8 | sudo tee -a /etc/resolv.conf
        echo nameserver 8.8.4.4 | sudo tee -a /etc/resolv.conf
    }

#Firewall
    LcLib_install_firewall() {
        PROGRAM=$1
        if [ "$PROGRAM" = "ufw" ]; then 
            LcLib_printer "INSTALL UFW" INSTALL
            sudo ${packageManager} install ufw -y
        elif [ "$PROGRAM" = "iptables" ]; then 
            LcLib_printer "INSTALL IPTABLES" INSTALL
            sudo ${packageManager} install iptables -y
            echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
            echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
            sudo ${packageManager} -y install iptables-persistent
        else
            LcLib_printer "$1 UNSUPPORTED INSTALLATION" ERROR
        fi
    }
    LcLib_update_firewall() {
        PROGRAM=$1
        VERSION=$2
        LcLib_wget_testExec '${LINK_UPDATE_FIREWALL_FILE}update-${PROGRAM}-${VERSION}.sh' INSTALL "UPDATE ${PROGRAM} ${VERSION}"
    }

#Docker
    LcLib_install_docker() {
        LcLib_wget_testExec LINK_DOCKER_INSTALL INSTALL "INSTALL DOCKER"

        #Verif if iptables install
        ##/sbin/iptables-save > /etc/iptables/rules.v4
        ##/sbin/ip6tables-save > /etc/iptables/rules.v6
    }
    LcLib_install_dockerCompose() {
        if [[ `wget -S --spider "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)" 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
            LcLib_printer "INSTALL DOCKER COMPOSE" INSTALL
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            docker-compose --version
        else
            LcLib_printer "ERROR INSTALL DOCKER COMPOSE" ERROR
        fi
    }

#Node-Avalanche


#ANSSI
    LcLib_anssi_conf() {
        #ivp6=$1 #False for disable IPV6
        #Sysctl Configuration
        sudo wget -qO - $LINK_ANSSI_CONF | sudo bash #-s ${ipv6}
    }
#===============================
#Check if we can import .env; else we init it.
LcLib_check_not_superuser
LcLib_check_envVariable
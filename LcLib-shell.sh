#!/bin/bash

# LCLib-shell.sh
# This is a shell library.
# Version 1 consists of functions to use when deploying a server.
#© 2022 Clément Levoux

#Links
LINK_UPDATE_FIREWALL_FILE='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/firewall/'
LINK_ANSSI_CONF='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/Anssi/anssi_conf.sh'
LINK_SSH_KEYS='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/ssh/keys/'
LINK_SSH_CONFIG='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/ssh/sshd_config'
LINK_SSH_BANNER='https://raw.githubusercontent.com/clementlvx/LcLib-shell/master/ssh/issue.net'
LINK_DOCKER_INSTALL='https://raw.githubusercontent.com/docker/docker-install/master/install.sh'
LINK_DOCKERCOMPOSE_INSTALL='https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-'

if [[ "${*}" =~ "-debug" ]]; then DEBUG=ON; fi

UNAME_S=$(uname -s)
UNAME_M=$(uname -m)
LOG_DIR=/var/log
LOG_DATE=$(date +"%m-%d-%y_%Hh%M")

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

#Logs
    #Command echo - LcLib_printer "Bonjour" ERROR
    LcLib_printer() {
        text=$1
        color=$2
        log=$3
        echo -e "${!color}${text}${NORMAL}"
        #if log == true { print in logfile }
    }
    LcLib_printer_loading() {
        text=$1
        status=$2
        if [ "$status" = "ERROR" ]; then
            echo -e -ne "${ERROR}--> ${text} - ERROR${NORMAL}\r"
            echo -e -ne "\n"
        elif [ "$status" = "OK" ]; then
            echo -e -ne "${OK}--> ${text} - DONE${NORMAL}\r"
            echo -e -ne "\n"
        elif [ "$status" = "ALREADY" ]; then
            echo -e -ne "${OK}--> ${text} - ALREADY INSTALLED${NORMAL}\r"
            echo -e -ne "\n"
        else
            echo -e -ne "${INSTALL}--> ${text} - ...${NORMAL}\r"
        fi
        #if log == true { print in logfile }
    }
    LcLib_Log() { #A tester LcLib_Log "text"
        TEXT=$1
        NOW=$(date +"%m/%d/%y %Hh%M")
        echo "${NOW} ${TEXT}" >> "./${LOG_DATE}_LCLIB"
    }

#Other
    LcLib_execNull() {
        command=$1
        if [ "$DEBUG" = "ON" ]; then
            sudo sh -c "${command}"
        else
            sudo sh -c "${command}" &> /dev/null
        fi
    }
    LcLib_testLink(){
        link=$1
        if [[ `wget -S --spider "${link}" 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
            echo "ok"
        fi
    }
    LcLib_alreadyInstalled(){
        program=$1
        LcLib_execNull "command -v ${program}"
    }
    LcLib_update_system() { # LcLib_update_system
        LcLib_printer "--> UPDATE SYSTEM" INFO
        LcLib_execNull "apt-get -qq update && apt-get -qq upgrade -y && apt-get -qq full-upgrade -y && apt-get -qq autoremove -y"
    }
    LcLib_justInstall(){ # LcLib_justInstall tree gcc ...
        OPTION=$1
        PROGRAMS=${@:2}
        
        LcLib_update_system
        for i in $PROGRAMS; do
            LcLib_printer_loading "${i}" INSTALL
            if ! LcLib_alreadyInstalled "${i}"; then
                if [ "$OPTION" = "-force" ]; then
                    LcLib_execNull "apt-get install -y ${i}"
                    LcLib_printer_loading "${i}" OK
                else
                    if LcLib_execNull "apt-get install -y ${i}"; then
                        if ! LcLib_alreadyInstalled "${i}"; then
                            LcLib_printer_loading "${i}" ERROR
                        else
                            LcLib_printer_loading "${i}" OK
                        fi
                    else
                        LcLib_printer_loading "${i}" ERROR
                    fi
                fi
            else
                LcLib_printer_loading "${i}" ALREADY
            fi
        done
    }

#===============================
#Checks
    #Check if sudo are installed, else install it - checkInstall_sudo
    LcLib_check_Install_sudo() { # LcLib_check_Install_sudo
        if ! hash sudo 2>/dev/null; then
            LcLib_printer "SUDO INSTALLATION" INSTALL
            su -c "apt-get install sudo ; echo '$USER ALL=(ALL:ALL) ALL' | sudo EDITOR='tee -a' visudo" &> /dev/null
        fi
    }

    #Check if script are run with root - check_not_superuser
    LcLib_check_not_superuser() { # LcLib_check_not_superuser
        #not superuser check
        if ! [ "$EUID" -ne 0 ] ; then
            LcLib_printer "Dont run this script as root, run as the user whose environment u want to change." ERROR
            exit
        fi
    }
#Hostname
    LcLib_update_hostname() { # LcLib_update_hostname "hostname"
        if [ "${HOSTNAME}" != "${1}" ]; then
            LcLib_execNull "hostnamectl set-hostname ${1}"
            LcLib_execNull "echo '127.0.0.1   ${1}' | sudo tee -a /etc/hosts"
            LcLib_execNull "echo '${2}   ${1}' | sudo tee -a /etc/hosts"
        fi
    }
#SSH
    LcLib_get_sshPort() { # LcLib_get_sshPort
        cat /etc/ssh/sshd_config | grep "Port " | cut -d " " -f 2
    }
    #Check if script are run with root - check_not_superuser
    LcLib_update_ssh() { #LcLib_update_ssh 22 clm claude françois
        SSH_PORT=$1
        SSH_KEYS=${@:2}

        sh -c "rm -rf ~/.ssh"
        sh -c "mkdir ~/.ssh"
        sh -c "chmod 700 ~/.ssh"
        for i in ${SSH_KEYS}; do
            sh -c "wget -qO - '${LINK_SSH_KEYS}${i}'| tee -a ~/.ssh/authorized_keys" &> /dev/null
        done
        sh -c "chmod 600 ~/.ssh/authorized_keys" &> /dev/null
        LcLib_execNull "wget -O /etc/issue.net ${LINK_SSH_BANNER}"
        LcLib_execNull "wget -O /etc/ssh/sshd_config ${LINK_SSH_CONFIG}"
        LcLib_execNull "sed -i 's/Port 22/Port ${SSH_PORT}/' /etc/ssh/sshd_config"
        LcLib_execNull "service ssh restart"
        LcLib_printer_loading "SSH CONF ${*}" OK
    }

#DNS
    LcLib_get_dns() { # LcLib_get_dns
        res=$(cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2) #Get DNS
        for i in ${res}; do
            echo ${i}
        done
    }
    LcLib_update_dns() { # LcLib_update_dns 1.1.1.1 8.8.8.8 8.8.4.4
        res=$(LcLib_get_dns) #Get DNS
        LcLib_printer_loading "DNS ${*}" OK
        for i in $*; do
            if [[ ! "${res[*]}" =~ "${i}" ]]; then
                LcLib_execNull "echo nameserver ${i} | tee -a /etc/resolv.conf"
            fi
        done
    }

#Firewall
    LcLib_install_firewall() { # LcLib_install_firewall iptables
        PROGRAM=$1
        if [ "$PROGRAM" = "ufw" ]; then 
            LcLib_justInstall "-classic" "ufw"
        elif [ "$PROGRAM" = "iptables" ]; then 
            LcLib_justInstall "-classic" "iptables"
            LcLib_execNull "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections"
            LcLib_execNull "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections"
            LcLib_justInstall "-force" "iptables-persistent"
        else
            LcLib_printer "$1 UNSUPPORTED INSTALLATION" ERROR
        fi
    }
    LcLib_update_firewall() { # LcLib_update_firewall iptables docker
        PROGRAM=$1 #Firewall used
        VERSION=$2 #Script Version
        SSH_PORT=$(LcLib_get_sshPort) #Get SSH
        DNS=$(LcLib_get_dns) #Get DNS

        LcLib_printer_loading "${PROGRAM} ${VERSION} CONF" INSTALL

        res=$(LcLib_testLink "${LINK_UPDATE_FIREWALL_FILE}update_${PROGRAM}_${VERSION}.sh") #Test Script Link
        if [ "$res" = "ok" ]; then
            LcLib_execNull "wget -qO - "${LINK_UPDATE_FIREWALL_FILE}update-${PROGRAM}-${VERSION}.sh" | bash"
            LcLib_printer_loading "${PROGRAM} ${VERSION} CONF" OK
        else
            LcLib_printer_loading "${PROGRAM} ${VERSION} CONF" ERROR
        fi
    }

#Docker
    LcLib_install_docker() { # LcLib_install_docker
        LcLib_printer_loading "DOCKER" INSTALL
        #res=$(LcLib_alreadyInstalledd "docker") #Test if program already installed
        if ! LcLib_alreadyInstalled "docker"; then
            res=$(LcLib_testLink ${LINK_DOCKER_INSTALL}) #Test Docker Link
            if [ "$res" = "ok" ]; then
                LcLib_execNull "wget -qO - ${LINK_DOCKER_INSTALL} | bash"
                if command -v docker >/dev/null; then
                    LcLib_printer_loading "DOCKER" OK
                else
                    LcLib_printer_loading "DOCKER" ERROR
                fi
            else
                LcLib_printer_loading "DOCKER" ERROR
            fi
        else
            LcLib_printer_loading "DOCKER" ALREADY
        fi
        #Verif if iptables install
        ##/sbin/iptables-save > /etc/iptables/rules.v4
        ##/sbin/ip6tables-save > /etc/iptables/rules.v6
    }
    LcLib_install_dockerCompose() { #LcLib_install_dockerCompose
        LcLib_printer_loading "DOCKER-COMPOSE" INSTALL
        if ! LcLib_alreadyInstalled "docker-compose"; then
            LcLib_execNull "curl -L "${LINK_DOCKERCOMPOSE_INSTALL}${UNAME_S}-${UNAME_M}" -o /usr/local/bin/docker-compose"
            LcLib_execNull "chmod +x /usr/local/bin/docker-compose"
            if ! LcLib_alreadyInstalled "docker-compose"; then
                LcLib_printer_loading "DOCKER-COMPOSE" ERROR
            else
                LcLib_printer_loading "DOCKER-COMPOSE" OK
            fi
        else
            LcLib_printer_loading "DOCKER-COMPOSE" ALREADY
        fi
    }


#ANSSI
    LcLib_anssi_conf() { #LcLib_anssi_conf
        #ivp6=$1 #False for disable IPV6
        #Sysctl Configuration
        LcLib_printer_loading "ANSSI CONF" OK
        LcLib_execNull "wget -qO - ${LINK_ANSSI_CONF} | sudo bash"
    }
#===============================
#Check if we can import .env; else we init it.
LcLib_check_not_superuser
#LcLib_check_envVariable

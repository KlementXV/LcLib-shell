#!/bin/bash

# update_ufw_avalanche.sh
# This is a configuration for ufw used with avalanche
# Inspired by https://nicolas-avalabs.gitbook.io/avalanche-documentation/tutoriels/noeuds-et-mise-en-jeu/executer-un-noeud-avalanche-avec-ovh
# ©2022 Clément Levoux

SSH_PORT=$1
DNS=${@:2}

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 9651
sudo ufw allow ${SSH_PORT} #SSHPORT ENTRY
sudo ufw enable
sudo ufw status verbose
#!/bin/bash

# Charger les configurations
source ./config.conf
SERVICES_CONF="./services.conf"

# Fonction : Vérifier l'utilisateur
check_user() {
    if [[ "$require_su_check" == "yes" ]]; then
        current_user=$(whoami)
        if [[ "$current_user" != "$userSU" ]]; then
            echo "Ce script doit être exécuté en tant que $userSU. Basculer sur $userSU..."
            su - "$userSU" -c "$0"
            exit
        fi
    fi
}

# Fonction : Lire une section du fichier de configuration
read_section() {
    local section="$1"
    awk -v section="[$section]" '$0 ~ section {flag=1; next} /^

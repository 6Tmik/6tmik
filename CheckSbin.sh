#!/bin/bash

# Fichier de configuration
CONFIG_FILE="config_services.txt"

# Fonction pour vérifier si un service est installé
check_service_installed() {
    local service=$1
    dpkg -l | grep -qw "$service" && echo "installé" || echo "non installé"
}

# Fonction pour vérifier si un service est actif
check_service_active() {
    local service=$1
    systemctl is-active "$service" &>/dev/null && echo "actif" || echo "inactif"
}

# Fonction pour obtenir le paquet associé
get_package_associated() {
    local binary=$1
    dpkg -S "$binary" 2>/dev/null | awk -F: '{print $1}'
}

# Lire la configuration et appliquer les règles
while read -r line; do
    # Ignorer les commentaires et les lignes vides
    [[ $line =~ ^#.*$ || -z $line ]] && continue

    service=$(echo "$line" | awk '{print $1}')
    action=$(echo "$line" | awk '{print $2}')

    echo "Analyse du service : $service"

    installed=$(check_service_installed "$service")
    active=$(check_service_active "$service")
    package=$(get_package_associated "$service")

    echo " - Installé : $installed"
    echo " - Actif : $active"
    echo " - Paquet associé : $package"

    case $action in
        SUPPRIMER)
            if [[ $installed == "installé" ]]; then
                echo "   -> Suppression de $service"
                sudo apt remove -y "$package"
            else
                echo "   -> Non installé, aucune action nécessaire."
            fi
            ;;
        DESACTIVER)
            if [[ $active == "actif" ]]; then
                echo "   -> Désactivation de $service"
                sudo systemctl disable "$service"
                sudo systemctl stop "$service"
            else
                echo "   -> Déjà inactif, aucune action nécessaire."
            fi
            ;;
        GARDER)
            echo "   -> Aucun changement, le service est conservé."
            ;;
        *)
            echo "   -> Action inconnue pour $service, vérifiez la configuration."
            ;;
    esac
    echo ""
done < "$CONFIG_FILE"

echo "Analyse terminée.

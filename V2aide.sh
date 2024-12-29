#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE AIDE
# ================================

# Étape 1 : Installer AIDE
echo "Installation de AIDE..."
sudo apt update
sudo apt install -y aide

# Étape 2 : Initialiser la base de données AIDE
echo "Initialisation de la base de données AIDE..."
sudo aideinit
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Étape 3 : Configurer AIDE pour surveiller des chemins spécifiques
echo "Configuration de AIDE..."
sudo cp /etc/aide/aide.conf /etc/aide/aide.conf.backup
sudo sed -i '/\/var\/log/ s/ALL$/+p+u+g/' /etc/aide/aide.conf
sudo sed -i '/\/etc\/passwd/ s/ALL$/+p+u+g+c/' /etc/aide/aide.conf

# Étape 4 : Planifier une vérification régulière (via cron)
echo "Planification d'une vérification quotidienne avec cron..."
echo "0 3 * * * root /usr/bin/aide.wrapper --check" | sudo tee -a /etc/cron.d/aide-check

echo "AIDE est maintenant installé et configuré."
echo "Vous pouvez exécuter une vérification manuelle avec : sudo aide.wrapper --check

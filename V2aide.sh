#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE AIDE
# ================================
# Instructions :
# 1. Installe AIDE pour surveiller et vérifier l'intégrité des fichiers.
# 2. Commandes utiles :
#    - Initialiser AIDE : sudo aideinit
#    - Vérification manuelle : sudo aide.wrapper --check
#    - Modifier la configuration : sudo nano /etc/aide/aide.conf
#    - Logs des vérifications : sudo less /var/log/aide/aide.log
# 3. Planification automatique :
#    - Vérifications quotidiennes planifiées via cron.
# 4. Chemins surveillés par défaut :
#    - /etc/passwd (permissions, utilisateur, groupe, contenu)
#    - /var/log (permissions, utilisateur, groupe)

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
echo "Vous pouvez exécuter une vérification manuelle avec : sudo aide.wrapper --check"

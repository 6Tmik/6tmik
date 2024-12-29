#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE KIPPO/COWRIE
# ================================
# Instructions :
# 1. Cowrie est un honeypot SSH interactif qui simule un système vulnérable.
# 2. Commandes utiles :
#    - Démarrer Cowrie : ./start.sh
#    - Arrêter Cowrie : ./stop.sh
#    - Logs des attaques : cowrie/var/log/cowrie/cowrie.json
# 3. Les sessions des attaquants sont enregistrées pour analyse.

# Étape 1 : Installer les dépendances nécessaires
echo "Installation des dépendances pour Cowrie..."
sudo apt update
sudo apt install -y git python3-venv python3-pip libffi-dev libssl-dev

# Étape 2 : Cloner le dépôt Cowrie
echo "Clonage du dépôt Cowrie..."
git clone https://github.com/cowrie/cowrie.git
cd cowrie

# Étape 3 : Configurer Cowrie
echo "Configuration de Cowrie..."
cp cowrie.cfg.dist cowrie.cfg
sed -i 's/^hostname = svr03/hostname = honeypot/' cowrie.cfg
sed -i 's/^listen_port = 2222/listen_port = 22222/' cowrie.cfg

# Étape 4 : Configurer un environnement virtuel Python
echo "Configuration de l'environnement virtuel Python..."
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Étape 5 : Démarrer Cowrie
echo "Démarrage de Cowrie..."
./start.sh

echo "Cowrie est maintenant actif et écoute sur le port 22222."
echo "Consultez les logs dans cowrie/var/log/cowrie/cowrie.json

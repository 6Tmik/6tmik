#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE ZEEK
# ================================

# Étape 1 : Installer les dépendances
echo "Installation des dépendances nécessaires..."
sudo apt update
sudo apt install -y cmake make gcc g++ flex bison libpcap-dev libssl-dev python3 python3-pip zlib1g-dev libmaxminddb-dev

# Étape 2 : Télécharger et installer Zeek
echo "Téléchargement de Zeek..."
wget https://download.zeek.org/zeek-5.1.2.tar.gz
tar -xvzf zeek-5.1.2.tar.gz
cd zeek-5.1.2

echo "Compilation et installation de Zeek..."
./configure --prefix=/opt/zeek
make
sudo make install

# Étape 3 : Ajouter Zeek au PATH
echo "Ajout de Zeek au PATH..."
echo "export PATH=\$PATH:/opt/zeek/bin" >> ~/.bashrc
source ~/.bashrc

# Étape 4 : Configurer l'interface réseau pour Zeek
echo "Configuration de l'interface réseau pour Zeek..."
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
echo "Interface détectée : $INTERFACE"

# Étape 5 : Démarrer Zeek
echo "Démarrage de Zeek..."
sudo /opt/zeek/bin/zeekctl deploy

# Étape 6 : Vérification des logs de Zeek
echo "Zeek est maintenant installé et configuré."
echo "Les logs sont disponibles dans /opt/zeek/logs/current/.

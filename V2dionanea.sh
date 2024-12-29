#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE DIONAEA
# ================================
# Instructions :
# 1. Dionaea est un honeypot qui capture des malwares en simulant des services vulnérables.
# 2. Commandes utiles :
#    - Démarrer Dionaea : sudo systemctl start dionaea
#    - Arrêter Dionaea : sudo systemctl stop dionaea
#    - Logs des activités : /var/dionaea/log/dionaea.log
# 3. Configuration typique :
#    - Le fichier de configuration principal est : /etc/dionaea/dionaea.conf
#    - Les malwares capturés sont enregistrés dans : /var/dionaea/binaries
#    - Les interactions réseau sont enregistrées dans : /var/dionaea/log/
# 4. Exemple de services simulés :
#    - SMB, FTP, HTTP, TFTP, MySQL, etc.
# 5. Par défaut, Dionaea utilise SQLite pour stocker les sessions.

# Étape 1 : Installer les dépendances pour Dionaea
echo "Installation des dépendances pour Dionaea..."
sudo apt update
sudo apt install -y git cmake build-essential libglib2.0-dev libssl-dev python3-pip sqlite3

# Étape 2 : Cloner le dépôt Dionaea
echo "Clonage du dépôt Dionaea..."
git clone https://github.com/DinoTools/dionaea.git
cd dionaea

# Étape 3 : Configurer Dionaea
echo "Configuration de Dionaea..."
cmake -DCMAKE_INSTALL_PREFIX=/opt/dionaea \
      -DENABLE_SQLITE=ON \
      -DENABLE_HONEYD=OFF
make
sudo make install

# Étape 4 : Configurer les logs et répertoires
echo "Configuration des répertoires de logs et malwares capturés..."
sudo mkdir -p /var/dionaea/log
sudo mkdir -p /var/dionaea/binaries
sudo chmod -R 755 /var/dionaea

# Étape 5 : Démarrer Dionaea
echo "Démarrage de Dionaea..."
/opt/dionaea/bin/dionaea -c /opt/dionaea/etc/dionaea/dionaea.conf -D

echo "Dionaea est maintenant actif et capture les malwares."
echo "Les malwares capturés sont enregistrés dans /var/dionaea/binaries."
echo "Les logs sont enregistrés dans /var/dionaea/log/dionaea.log.

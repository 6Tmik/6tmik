#!/bin/bash

# Installer les dépendances pour Zabbix
echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y wget gnupg

# Ajouter le dépôt officiel de Zabbix
echo "Ajout du dépôt Zabbix..."
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian12_all.deb
sudo dpkg -i zabbix-release_6.0-4+debian12_all.deb
sudo apt update

# Installer le serveur Zabbix et l'agent
echo "Installation de Zabbix Server et de l'agent..."
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Installer et configurer MariaDB
echo "Installation de MariaDB..."
sudo apt install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Créer la base de données pour Zabbix
echo "Configuration de la base de données..."
sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
sudo mysql -e "CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Importer les schémas initiaux
echo "Importation des schémas initiaux..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p'password' zabbix

# Configurer Zabbix Server
echo "Configuration de Zabbix Server..."
sudo sed -i 's/# DBPassword=/DBPassword=password/' /etc/zabbix/zabbix_server.conf
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "Zabbix est maintenant installé et configuré. Accédez à http://<votre_ip>/zabbix pour finaliser la configuration dans l'interface web.

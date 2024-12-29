#!/bin/bash

echo "### Script 1 : Configuration initiale ###"

# Bloc 1 : Désactivation des services inutiles (Bluetooth, Avahi, WPA, etc.)
echo "Bloc 1 : Désactivation des services inutiles..."
services_to_disable=(
  "saned.service"
  "postfix.service"
  "bluetooth.service"
  "avahi-daemon.service"
  "wpa_supplicant.service"
  "cups.service"
)

for service in "${services_to_disable[@]}"; do
  sudo systemctl disable $service
  sudo systemctl stop $service
  echo "$service désactivé et arrêté."
done

# Bloc 7 : Suppression de l'utilisateur `saned`
echo "Bloc 7 : Suppression de l'utilisateur saned..."
if id "saned" &>/dev/null; then
  sudo userdel -r saned
  echo "Utilisateur saned supprimé."
else
  echo "Utilisateur saned non présent."
fi



# Bloc 9 : Ajout de l'utilisateur aux groupes nécessaires
echo "Bloc 9 : Ajout de l'utilisateur aux groupes nécessaires..."
sudo usermod -aG adm,systemd-journal $USER
echo "Utilisateur $USER ajouté aux groupes adm et systemd-journal."

# Bloc 10 : Modification des permissions des fichiers critiques
echo "Bloc 10 : Modification des permissions des fichiers critiques..."
sudo chmod 640 /etc/shadow
sudo chown root:shadow /etc/shadow
sudo chmod 644 /etc/passwd
sudo chown root:root /etc/passwd
sudo chmod 644 /etc/group
sudo chown root:root /etc/group
sudo chmod 440 /etc/sudoers
sudo chown root:root /etc/sudoers
echo "Permissions des fichiers critiques mises à jour."


echo "### Script 1 terminé ###"


echo "### Script 2 : Gestion simplifiée des services ###"

# Bloc 1 : Vérification des services Apache, MySQL, et PHP
echo "Bloc 1 : Vérification des services Web (Apache, MySQL, PHP)..."
if dpkg -l | grep -q apache2; then
  echo "Apache2 est installé."
else
  echo "Apache2 n'est pas installé."
fi

if dpkg -l | grep -q mysql; then
  echo "MySQL est installé."
else
  echo "MySQL n'est pas installé."
fi

if php -v &>/dev/null; then
  php_version=$(php -v | head -n 1)
  echo "PHP est installé : $php_version"
else
  echo "PHP n'est pas installé."
fi

# Bloc 2 : Désactivation de SSH si inutile
echo "Bloc 2 : Désactivation de SSH..."
sudo systemctl disable ssh.service
sudo systemctl stop ssh.service
sudo apt remove --purge openssh-server -y
echo "SSH désactivé."

# Bloc 11 : Vérification des services actifs
echo "Bloc 11 : Vérification des services actifs après configuration..."
systemctl list-units --type=service --state=running

echo "### Script 2 terminé ###"

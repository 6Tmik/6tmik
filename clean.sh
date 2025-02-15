#!/bin/bash

# Vérification des privilèges root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    echo "Relancez-le avec 'sudo'."
    exit 1
fi

# Journalisation
LOG_FILE="/var/log/system_config.log"
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "### Début du script complet ###"

# Bloc 1 : Désactivation des services inutiles
log_message "Bloc 1 : Désactivation des services inutiles..."
services_to_disable=(
    "saned.service"
    "postfix.service"
    "bluetooth.service"
    "avahi-daemon.service"
    "wpa_supplicant.service"
    "cups.service"
    "bluetooth"
    "avahi-daemon"
    "smbd"
    "rygel"
    "nfs-server"
    "rpcbind"
    "NetworkManager-wait-online.service"
    "ModemManager"
)

for service in "${services_to_disable[@]}"; do
    systemctl stop "$service" && log_message "Service $service arrêté."
    systemctl disable "$service" && log_message "Service $service désactivé."
    systemctl mask "$service" && log_message "Service $service masqué."
done

# Bloc 7 : Suppression de l'utilisateur `saned`
log_message "Bloc 7 : Suppression de l'utilisateur saned..."
if id "saned" &>/dev/null; then
    userdel -r saned && log_message "Utilisateur saned supprimé."
else
    log_message "Utilisateur saned non présent."
fi

# Bloc 9 : Ajout de l'utilisateur aux groupes nécessaires
log_message "Bloc 9 : Ajout de l'utilisateur aux groupes nécessaires..."
usermod -aG adm,systemd-journal "$USER" && log_message "Utilisateur $USER ajouté aux groupes adm et systemd-journal."

# Bloc 10 : Modification des permissions des fichiers critiques
log_message "Bloc 10 : Modification des permissions des fichiers critiques..."
chmod 640 /etc/shadow && chown root:shadow /etc/shadow && log_message "Permissions de /etc/shadow mises à jour."
chmod 644 /etc/passwd && chown root:root /etc/passwd && log_message "Permissions de /etc/passwd mises à jour."
chmod 644 /etc/group && chown root:root /etc/group && log_message "Permissions de /etc/group mises à jour."
chmod 440 /etc/sudoers && chown root:root /etc/sudoers && log_message "Permissions de /etc/sudoers mises à jour."

# Bloc 2 : Vérification des services Apache, MySQL, et PHP
log_message "Bloc 2 : Vérification des services Web (Apache, MySQL, PHP)..."
if dpkg -l | grep -q apache2; then
    log_message "Apache2 est installé."
else
    log_message "Apache2 n'est pas installé."
fi

if dpkg -l | grep -q mysql; then
    log_message "MySQL est installé."
else
    log_message "MySQL n'est pas installé."
fi

if php -v &>/dev/null; then
    php_version=$(php -v | head -n 1)
    log_message "PHP est installé : $php_version"
else
    log_message "PHP n'est pas installé."
fi

# Bloc 2 bis : Désactivation de SSH si inutile
log_message "Bloc 2 bis : Désactivation de SSH..."
systemctl stop ssh.service && log_message "Service SSH arrêté."
systemctl disable ssh.service && log_message "Service SSH désactivé."
apt remove --purge openssh-server -y && log_message "Paquet openssh-server supprimé."

# Bloc 4 : Suppression des paquets inutiles
PACKAGES_TO_REMOVE=(
    "telnet"
    "vsftpd"
    "proftpd"
    "tftpd-hpa"
    "snmp"
)

log_message "Bloc 4 : Suppression des paquets inutiles..."
for package in "${PACKAGES_TO_REMOVE[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        apt remove --purge -y "$package" && log_message "Paquet $package supprimé."
    else
        log_message "Paquet $package non installé."
    fi
done

# Nettoyage des dépendances inutilisées
log_message "Nettoyage des dépendances inutilisées..."
apt autoremove -y && log_message "Dépendances inutilisées supprimées."
apt autoclean -y && log_message "Caches de paquets nettoyés."

# Bloc 5 : Vérification des services actifs
log_message "Bloc 5 : Vérification des services actifs..."
systemctl list-units --type=service --state=running | tee -a "$LOG_FILE"

log_message "### Fin du script complet ###"

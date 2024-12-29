#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    su - su -c "$0"
    exit 0
fi

echo "Début de la configuration réseau et sécurité..."

# Étape 1 : Sauvegarde des fichiers critiques
echo "Sauvegarde des fichiers de configuration..."
CONFIG_FILES=(
    "/etc/sysctl.conf"
    "/etc/NetworkManager/NetworkManager.conf"
    "/etc/resolv.conf"
    "/etc/fail2ban/jail.local"
)

for FILE in "${CONFIG_FILES[@]}"; do
    if [[ -f "$FILE" ]]; then
        cp "$FILE" "$FILE.bak"
        echo "Sauvegarde effectuée : $FILE.bak"
    else
        echo "Le fichier $FILE n'existe pas encore. Il sera créé."
    fi
done

# Fonction : pause et modification manuelle
pause_and_edit() {
    local FILE="$1"
    local CONTENT="$2"

    echo "Vous allez modifier le fichier : $FILE"
    echo "Voici le contenu proposé à ajouter ou remplacer :"
    echo "------------------------------------------"
    echo "$CONTENT"
    echo "------------------------------------------"
    read -p "Appuyez sur Entrée pour ouvrir l'éditeur (ou Ctrl+C pour annuler)."
    nano "$FILE"
}

# Étape 2 : Configuration de NetworkManager
NETWORKMANAGER_CONFIG="/etc/NetworkManager/NetworkManager.conf"
NETWORKMANAGER_CONTENT="[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
wwan.cloned-mac-address=random"

pause_and_edit "$NETWORKMANAGER_CONFIG" "$NETWORKMANAGER_CONTENT"

# Étape 3 : Configuration de sysctl.conf
SYSCTL_CONFIG="/etc/sysctl.conf"
SYSCTL_CONTENT="# Désactiver IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Protection contre le spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Protection contre les SYN floods
net.ipv4.tcp_syncookies = 1

# Désactiver les redirections ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Désactiver les paquets source-routed
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0"

pause_and_edit "$SYSCTL_CONFIG" "$SYSCTL_CONTENT"
sysctl -p
echo "Configuration sysctl appliquée."

# Étape 4 : Configuration de resolv.conf
RESOLV_CONF="/etc/resolv.conf"
RESOLV_CONTENT="nameserver 9.9.9.9
nameserver 1.1.1.1"

pause_and_edit "$RESOLV_CONF" "$RESOLV_CONTENT"

# Étape 5 : Configuration de Fail2ban
FAIL2BAN_CONFIG="/etc/fail2ban/jail.local"
FAIL2BAN_CONTENT="[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 2
bantime = 33333600"

pause_and_edit "$FAIL2BAN_CONFIG" "$FAIL2BAN_CONTENT"
systemctl restart fail2ban
echo "Fail2ban configuré et redémarré."

# Étape 6 : Configuration de Logwatch
LOGWATCH_SCRIPT="/usr/local/bin/logwatch_daily.sh"
LOGWATCH_CONTENT="#!/bin/bash
/usr/sbin/logwatch --output mail --mailto root --detail high"

pause_and_edit "$LOGWATCH_SCRIPT" "$LOGWATCH_CONTENT"
chmod +x "$LOGWATCH_SCRIPT"
echo "Logwatch configuré. Script ajouté pour exécution quotidienne."

# Vérification finale
echo "Vérification des fichiers modifiés..."
FILES_TO_VERIFY=(
    "$SYSCTL_CONFIG"
    "$NETWORKMANAGER_CONFIG"
    "$RESOLV_CONF"
    "$FAIL2BAN_CONFIG"
    "$LOGWATCH_SCRIPT"
)

for FILE in "${FILES_TO_VERIFY[@]}"; do
    echo -e "\n# Contenu du fichier $FILE :"
    cat "$FILE"
done

echo "Configuration complète. Veuillez vérifier les paramètres manuellement si nécessaire.

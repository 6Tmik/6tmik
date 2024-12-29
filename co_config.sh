#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    echo "Relance avec sudo..."
    exit 1
fi

echo "Démarrage du script de configuration réseau et services..."

# Fonction pour sauvegarder les fichiers de configuration
backup_config() {
    local FILE="$1"
    if [[ -f "$FILE" ]]; then
        cp "$FILE" "$FILE.bak"
        echo "Sauvegarde effectuée : $FILE.bak"
    else
        echo "Le fichier $FILE n'existe pas encore. Il sera créé."
    fi
}

# Fonction pour pause et modification
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

# Liste des fichiers de configuration à sauvegarder
CONFIG_FILES=(
    "/etc/sysctl.conf"
    "/etc/NetworkManager/NetworkManager.conf"
    "/etc/resolv.conf"
    "/etc/fail2ban/jail.local"
)

# Sauvegarder les fichiers de configuration
for FILE in "${CONFIG_FILES[@]}"; do
    backup_config "$FILE"
done

# Étape 2 : Configuration de sysctl.conf
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

# Optimisation TCP
net.ipv4.tcp_max_syn_backlog = 2048
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_rmem = 4096 87380 6291456
net.ipv4.tcp_wmem = 4096 65536 6291456
net.ipv4.tcp_window_scaling = 1

# Protection avancée
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.log_martians = 1

# Désactiver les redirections ICMP
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Désactiver les paquets source-routed
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Renforcement du kernel
kernel.randomize_va_space = 2
fs.protected_symlinks = 1
fs.protected_hardlinks = 1"

pause_and_edit "$SYSCTL_CONFIG" "$SYSCTL_CONTENT"
sysctl -p
echo "Configuration sysctl appliquée."

# Étape 3 : Configuration de NetworkManager.conf
NETWORKMANAGER_CONFIG="/etc/NetworkManager/NetworkManager.conf"
NETWORKMANAGER_CONTENT="[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
wwan.cloned-mac-address=random"

pause_and_edit "$NETWORKMANAGER_CONFIG" "$NETWORKMANAGER_CONTENT"
echo "Configuration de NetworkManager appliquée."

# Étape 4 : Configuration de resolv.conf
RESOLV_CONF="/etc/resolv.conf"
RESOLV_CONTENT="nameserver 9.9.9.9
nameserver 1.1.1.1"

pause_and_edit "$RESOLV_CONF" "$RESOLV_CONTENT"
echo "Configuration de resolv.conf appliquée."

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

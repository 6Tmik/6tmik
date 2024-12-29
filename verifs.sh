#!/bin/bash

LOG_FILE="/var/log/security_audit.log"

# Vérification de l'utilisateur courant
if [ "$(whoami)" != "su" ]; then
    echo "Connexion à l'utilisateur 'su' requise. Basculons sur 'su'..."
    su - su -c "$0"
    exit 0
fi

# Initialisation du fichier log
echo "----- Audit de sécurité : $(date) -----" > "$LOG_FILE"

# Étape 1 : Vérification des utilisateurs et groupes
echo "Vérification des utilisateurs et groupes..." | tee -a "$LOG_FILE"
getent passwd >> "$LOG_FILE"
getent group >> "$LOG_FILE"
getent group sudo >> "$LOG_FILE"
sudo awk -F: '($2 == "") {print $1 " a un mot de passe vide"}' /etc/shadow >> "$LOG_FILE"

# Étape 2 : Vérification des services réseau actifs et ports ouverts
echo "Vérification des services réseau actifs et des ports ouverts..." | tee -a "$LOG_FILE"
sudo ss -tuln >> "$LOG_FILE"

# Étape 3 : Vérification des paramètres sysctl et des règles de pare-feu
echo "Vérification des paramètres sysctl et des règles de pare-feu..." | tee -a "$LOG_FILE"
sudo sysctl net.ipv4.tcp_syncookies >> "$LOG_FILE"
sudo sysctl -a | grep -E 'disable_ipv6|rp_filter|syncookies|accept_redirects|accept_source_route' >> "$LOG_FILE"
sudo iptables -L -v >> "$LOG_FILE"
sudo ip6tables -L -v >> "$LOG_FILE"

# Étape 4 : Vérification des permissions des fichiers critiques
echo "Vérification des permissions des fichiers critiques..." | tee -a "$LOG_FILE"
ls -l /etc/passwd /etc/shadow /etc/group /etc/sudoers >> "$LOG_FILE"
ls -l /etc/hosts.allow /etc/hosts.deny >> "$LOG_FILE"

# Étape 5 : Vérification des modifications de fichiers critiques
echo "Vérification des modifications dans /etc et /var..." | tee -a "$LOG_FILE"
sudo find /etc /var -type f -mtime -1 -exec ls -l {} \; >> "$LOG_FILE"

# Étape 6 : Recherche des fichiers avec des permissions suspectes
echo "Recherche des fichiers avec des permissions suspectes..." | tee -a "$LOG_FILE"
sudo find / -perm -4000 -o -perm -2000 -type f -exec ls -l {} \; >> "$LOG_FILE"
sudo find / -nouser -o -nogroup -exec ls -l {} \; >> "$LOG_FILE"

# Étape 7 : Vérification des répertoires avec accès en écriture
echo "Recherche des répertoires accessibles en écriture..." | tee -a "$LOG_FILE"
sudo find / -xdev -type d -perm -0002 -a ! -perm -1000 -exec ls -ld {} \; >> "$LOG_FILE"

# Étape 8 : Analyse des logs
echo "Analyse des logs pour les erreurs récentes..." | tee -a "$LOG_FILE"
sudo journalctl -p err --since "24 hour ago" >> "$LOG_FILE"
sudo dmesg | grep -i error >> "$LOG_FILE"
sudo cat /var/log/auth.log | grep -i "fail\|error" >> "$LOG_FILE"
sudo grep "IPTables-Dropped" /var/log/syslog >> "$LOG_FILE"
sudo journalctl -u ssh --since "24 hours ago" >> "$LOG_FILE"
sudo journalctl -u openvpn --since "24 hours ago" >> "$LOG_FILE"

# Étape 9 : Vérification des commandes sudo dans les logs
echo "Vérification des commandes sudo dans les logs..." | tee -a "$LOG_FILE"
sudo tail -n 50 /var/log/sudo.log >> "$LOG_FILE"
sudo grep "sudo:.*authentication failure" /var/log/auth.log >> "$LOG_FILE"

# Étape 10 : Vérification et correction des permissions des fichiers critiques
echo "Vérification et correction des permissions des fichiers critiques..." | tee -a "$LOG_FILE"
FILES_TO_CHECK=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/group"
    "/etc/sudoers"
    "/etc/ssh"
)

for FILE in "${FILES_TO_CHECK[@]}"; do
    CURRENT_PERM=$(stat -c "%a" "$FILE" 2>/dev/null || echo "NA")
    case "$FILE" in
        "/etc/passwd")
            EXPECTED_PERM=644 ;;
        "/etc/shadow")
            EXPECTED_PERM=600 ;;
        "/etc/group")
            EXPECTED_PERM=644 ;;
        "/etc/sudoers")
            EXPECTED_PERM=440 ;;
        "/etc/ssh")
            EXPECTED_PERM=700 ;;
    esac

    if [ "$CURRENT_PERM" != "$EXPECTED_PERM" ] && [ "$CURRENT_PERM" != "NA" ]; then
        echo "Permissions incorrectes détectées pour $FILE. Correction en cours..." | tee -a "$LOG_FILE"
        sudo chmod "$EXPECTED_PERM" "$FILE"
        echo "$(date) : Permissions corrigées pour $FILE (attendu : $EXPECTED_PERM, actuel : $CURRENT_PERM)" >> "$LOG_FILE"
    else
        echo "Permissions correctes pour $FILE (actuel : $CURRENT_PERM)." | tee -a "$LOG_FILE"
    fi
done

# Message de fin
echo "Audit terminé. Les résultats sont enregistrés dans $LOG_FILE.

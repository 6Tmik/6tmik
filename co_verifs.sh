#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root. Veuillez réessayer avec 'sudo'."
    exit 1
fi

LOG_FILE="/var/log/security_audit.log"

# Fonction pour journaliser
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Initialisation du fichier log
log_message "----- Audit de sécurité : $(date) -----"

# Étape 1 : Vérification des utilisateurs et groupes
log_message "Vérification des utilisateurs et groupes..."
getent passwd >> "$LOG_FILE"
getent group >> "$LOG_FILE"
getent group sudo >> "$LOG_FILE"
awk -F: '($2 == "") {print $1 " a un mot de passe vide"}' /etc/shadow >> "$LOG_FILE"

# Étape 2 : Vérification des services réseau actifs et ports ouverts
log_message "Vérification des services réseau actifs et des ports ouverts..."
ss -tuln >> "$LOG_FILE"

# Étape 3 : Vérification des paramètres sysctl et des règles de pare-feu
log_message "Vérification des paramètres sysctl et des règles de pare-feu..."
sysctl net.ipv4.tcp_syncookies >> "$LOG_FILE"
sysctl -a | grep -E 'disable_ipv6|rp_filter|syncookies|accept_redirects|accept_source_route' >> "$LOG_FILE"
iptables -L -v >> "$LOG_FILE"
ip6tables -L -v >> "$LOG_FILE"

# Étape 4 : Vérification des permissions des fichiers critiques
log_message "Vérification des permissions des fichiers critiques..."
ls -l /etc/passwd /etc/shadow /etc/group /etc/sudoers >> "$LOG_FILE"
ls -l /etc/hosts.allow /etc/hosts.deny >> "$LOG_FILE"

# Étape 5 : Vérification des modifications de fichiers critiques
log_message "Vérification des modifications dans /etc et /var..."
find /etc /var -type f -mtime -1 -exec ls -l {} \; >> "$LOG_FILE"

# Étape 6 : Recherche des fichiers avec des permissions suspectes
log_message "Recherche des fichiers avec des permissions suspectes..."
find / -perm -4000 -o -perm -2000 -type f -exec ls -l {} \; >> "$LOG_FILE"
find / -nouser -o -nogroup -exec ls -l {} \; >> "$LOG_FILE"

# Étape 7 : Vérification des répertoires avec accès en écriture
log_message "Recherche des répertoires accessibles en écriture..."
find / -xdev -type d -perm -0002 -a ! -perm -1000 -exec ls -ld {} \; >> "$LOG_FILE"

# Étape 8 : Analyse des logs
log_message "Analyse des logs pour les erreurs récentes..."
journalctl -p err --since "24 hour ago" >> "$LOG_FILE"
dmesg | grep -i error >> "$LOG_FILE"
cat /var/log/auth.log | grep -i "fail\|error" >> "$LOG_FILE"
grep "IPTables-Dropped" /var/log/syslog >> "$LOG_FILE"
journalctl -u ssh --since "24 hours ago" >> "$LOG_FILE"
journalctl -u openvpn --since "24 hours ago" >> "$LOG_FILE"

# Étape 9 : Vérification des commandes sudo dans les logs
log_message "Vérification des commandes sudo dans les logs..."
tail -n 50 /var/log/sudo.log >> "$LOG_FILE"
grep "sudo:.*authentication failure" /var/log/auth.log >> "$LOG_FILE"

# Étape 10 : Vérification et correction des permissions des fichiers critiques
log_message "Vérification et correction des permissions des fichiers critiques..."
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
        log_message "Permissions incorrectes détectées pour $FILE. Correction en cours..."
        chmod "$EXPECTED_PERM" "$FILE"
        log_message "Permissions corrigées pour $FILE (attendu : $EXPECTED_PERM, actuel : $CURRENT_PERM)"
    else
        log_message "Permissions correctes pour $FILE (actuel : $CURRENT_PERM)."
    fi
done

# Message de fin
log_message "Audit terminé. Les résultats sont enregistrés dans $LOG_FILE.

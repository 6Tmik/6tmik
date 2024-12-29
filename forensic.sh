#!/bin/bash

# Vérification de l'utilisateur courant
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root. Veuillez réessayer avec 'sudo'."
    exit 1
fi

# Variables pour les logs
LOG_FILE="/var/log/security_tools.log"

# Fonction pour journaliser
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Début de l'exécution du script."

# Étape 1 : Mise à jour et installation des outils
log_message "Mise à jour des dépôts et installation des outils requis..."
apt update -y

TOOLS=(
    "lynis"
    "rkhunter"
    "chkrootkit"
    "logwatch"
    "fail2ban"
    "clamav"
    "debsums"
)

for TOOL in "${TOOLS[@]}"; do
    if ! dpkg -l | grep -q "^ii.*$TOOL"; then
        log_message "Installation de $TOOL..."
        apt install -y "$TOOL"
    else
        log_message "$TOOL est déjà installé."
    fi
done

# Étape 2 : Exécution des outils
log_message "Exécution des outils de sécurité..."

log_message "Exécution de Lynis..."
lynis audit system --quick >> "$LOG_FILE" 2>&1

log_message "Exécution de RKHunter..."
rkhunter --update >> "$LOG_FILE" 2>&1
rkhunter --check --skip-keypress >> "$LOG_FILE" 2>&1

log_message "Exécution de Chkrootkit..."
chkrootkit >> "$LOG_FILE" 2>&1

log_message "Exécution de Fail2ban..."
fail2ban-client status >> "$LOG_FILE" 2>&1

log_message "Exécution de ClamAV (analyse rapide)..."
clamscan --infected --recursive / >> "$LOG_FILE" 2>&1

log_message "Exécution de Debsums (vérification des sommes de contrôle)..."
debsums -s >> "$LOG_FILE" 2>&1

log_message "Exécution de Logwatch (rapport journalier)..."
logwatch --output file --filename /var/log/logwatch.log --detail high >> "$LOG_FILE" 2>&1

# Étape 3 : Configuration du cron
log_message "Configuration du cron pour l'exécution quotidienne des outils..."
CRON_FILE="/etc/cron.daily/security_audit"
cat << EOF > $CRON_FILE
#!/bin/bash
rkhunter --update
rkhunter --check --skip-keypress >> /var/log/rkhunter.log 2>&1
chkrootkit >> /var/log/chkrootkit.log 2>&1
lynis audit system --quick >> /var/log/lynis.log 2>&1
clamscan --infected --recursive / >> /var/log/clamav.log 2>&1
debsums -s >> /var/log/debsums.log 2>&1
logwatch --output file --filename /var/log/logwatch.log --detail high >> /var/log/logwatch.log 2>&1
EOF
chmod +x $CRON_FILE

log_message "Le cron est configuré pour une exécution quotidienne."



# Bloc 1 : Installation de syslog si absent
echo "Bloc 1 : Installation de syslog si nécessaire..."
if ! dpkg -l | grep -q rsyslog; then
  echo "Syslog non installé. Installation en cours..."
  sudo apt update
  sudo apt install rsyslog -y
  sudo systemctl enable rsyslog.service
  sudo systemctl start rsyslog.service
else
  echo "Syslog déjà installé."
fi


# Étape 4 : Résumé
log_message "Script terminé avec succès. Tous les outils ont été exécutés, et la journalisation est disponible dans $LOG_FILE.

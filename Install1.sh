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

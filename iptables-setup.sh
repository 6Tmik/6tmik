

#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    echo "Relance avec sudo..."
    exit 1
fi

# Variables
INTERFACE="eth0"  # Interface principale (remplacez si nécessaire)
VM_NETWORK="192.168.122.0/24"  # Réseau des machines virtuelles
TEL_SUSPICIOUS_MAC="00:11:22:33:44:55"  # MAC Address de l'appareil suspect
TEL_SUSPICIOUS_IP="192.168.1.100"  # IP de l'appareil suspect
RULES_BACKUP_V4="$HOME/iptables-rules.v4"
RULES_BACKUP_V6="$HOME/ip6tables-rules.v6"
LOG_FILE="/var/log/iptables_block.log"

# Journalisation
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Début de la configuration des règles iptables."

# Suppression des règles existantes
log_message "Suppression des règles existantes..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

ip6tables -F
ip6tables -X
ip6tables -t nat -F
ip6tables -t nat -X
ip6tables -t mangle -F
ip6tables -t mangle -X
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT

# Politiques par défaut
log_message "Configuration des politiques par défaut..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT ACCEPT

# Loopback
log_message "Autorisation des connexions locales (loopback)..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Connexions établies et reliées
log_message "Autorisation des connexions établies et reliées..."
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Bloquer les protocoles non sécurisés
log_message "Blocage des protocoles non sécurisés..."
iptables -A INPUT -p tcp --dport 23 -j DROP  # Telnet
iptables -A INPUT -p udp --dport 5353 -j DROP  # mDNS
iptables -A INPUT -p udp -m multiport --dports 137,138 -j DROP  # NetBIOS
iptables -A INPUT -p tcp --dport 139 -j DROP  # SMB
iptables -A INPUT -p tcp --dport 445 -j DROP  # SMB

# Bloquer l'appareil suspect (par IP et MAC)
log_message "Blocage de l'appareil suspect..."
iptables -A INPUT -s "$TEL_SUSPICIOUS_IP" -j DROP
iptables -A INPUT -m mac --mac-source "$TEL_SUSPICIOUS_MAC" -j DROP

# Bloquer le WiFi, Bluetooth, partage de fichiers, et hotspot
log_message "Désactivation des services inutiles..."
rfkill block wifi
rfkill block bluetooth

# Bloquer tout le trafic multicast
log_message "Blocage du trafic multicast..."
iptables -A INPUT -m addrtype --dst-type MULTICAST -j DROP
iptables -A INPUT -m addrtype --dst-type BROADCAST -j DROP

# Bloquer les fuites DNS (IPv4 et IPv6)
log_message "Blocage des fuites DNS..."
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT  # DNS autorisé seulement si nécessaire
iptables -A OUTPUT -p udp ! --dport 53 -j DROP
ip6tables -A OUTPUT -p udp ! --dport 53 -j DROP

# Désactiver complètement IPv6 si non nécessaire
log_message "Désactivation de l'IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1

# NAT pour les VM
log_message "Configuration NAT pour les machines virtuelles..."
iptables -t nat -A POSTROUTING -s "$VM_NETWORK" -o "$INTERFACE" -j MASQUERADE
iptables -A FORWARD -s "$VM_NETWORK" -o "$INTERFACE" -j ACCEPT
iptables -A FORWARD -d "$VM_NETWORK" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Protection contre les attaques courantes
log_message "Mise en place des protections avancées..."
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# Journaux
log_message "Activation des journaux pour les paquets rejetés..."
iptables -A INPUT -j LOG --log-prefix "iptables INPUT DROP: " --log-level 4
ip6tables -A INPUT -j LOG --log-prefix "ip6tables INPUT DROP: " --log-level 4

# Sauvegarde des règles
log_message "Sauvegarde des règles..."
iptables-save > "$RULES_BACKUP_V4"
ip6tables-save > "$RULES_BACKUP_V6"

if [ -d "/etc/iptables" ]; then
    log_message "Copie des règles dans /etc/iptables..."
    cp "$RULES_BACKUP_V4" /etc/iptables/rules.v4
    cp "$RULES_BACKUP_V6" /etc/iptables/rules.v6
else
    log_message "Le dossier /etc/iptables n'existe pas. Installez iptables-persistent pour rendre les règles persistantes."
fi

# Vérification des règles
log_message "Vérification des règles actuelles..."
iptables -L -v --line-numbers | tee -a "$LOG_FILE"
ip6tables -L -v --line-numbers | tee -a "$LOG_FILE"

log_message "Configuration terminée avec succès."
exit 0







# Ajouts pour renforcer la sécurité et contrôler la VM

# Bloquer tout accès direct de la VM à l'hôte
log_message "Blocage de l'accès direct de la VM à l'hôte..."
iptables -A INPUT -s "$VM_NETWORK" -j DROP
iptables -A FORWARD -d "$VM_NETWORK" -o "$INTERFACE" -j DROP

# Empêcher les connexions non autorisées de la VM
log_message "Limitation des connexions sortantes de la VM..."
iptables -A FORWARD -s "$VM_NETWORK" -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s "$VM_NETWORK" -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s "$VM_NETWORK" -j DROP

# Bloquer les requêtes DHCP venant de la VM
log_message "Blocage des requêtes DHCP venant de la VM..."
iptables -A INPUT -p udp --sport 67 --dport 68 -j DROP
iptables -A FORWARD -p udp --sport 67 --dport 68 -j DROP

# Limiter le nombre de connexions TCP sortantes de la VM
log_message "Limitation des connexions TCP sortantes de la VM..."
iptables -A FORWARD -s "$VM_NETWORK" -p tcp --syn -m connlimit --connlimit-above 10 -j DROP

# Bloquer tout le trafic multicast et broadcast
log_message "Blocage du trafic multicast et broadcast..."
iptables -A INPUT -m addrtype --dst-type MULTICAST -j DROP
iptables -A FORWARD -m addrtype --dst-type MULTICAST -j DROP
iptables -A INPUT -m addrtype --dst-type BROADCAST -j DROP
iptables -A FORWARD -m addrtype --dst-type BROADCAST -j DROP

# Détection et blocage des scans de ports
log_message "Détection et blocage des scans de ports..."
iptables -N PORT_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -j PORT_SCAN
iptables -A PORT_SCAN -m limit --limit 1/s --limit-burst 4 -j RETURN
iptables -A PORT_SCAN -j LOG --log-prefix "Port Scan Detected: "
iptables -A PORT_SCAN -j DROP

# Journalisation des activités suspectes de la VM
log_message "Journalisation des activités suspectes de la VM..."
iptables -A INPUT -s "$VM_NETWORK" -j LOG --log-prefix "VM Suspicious Activity: "
iptables -A FORWARD -s "$VM_NETWORK" -j LOG --log-prefix "VM Suspicious Forward: "

# Bloquer le spoofing IP de la VM
log_message "Blocage des paquets avec des états invalides..."
iptables -A INPUT -s "$VM_NETWORK" -m conntrack --ctstate INVALID -j DROP
iptables -A FORWARD -s "$VM_NETWORK" -m conntrack --ctstate INVALID -j DRO

#!/bin/bash

# ================================
# SÉCURISATION DU SYSTÈME DEBIAN
# ================================

# Fonction pour détecter l'adresse IP et les plages réseau
detect_network() {
    echo "Détection des adresses réseau..."
    HOST_IP=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    HOST_NETWORK=$(ip route | grep eth0 | grep src | awk '{print $1}')
    VM_NETWORK="192.168.56.0/24"  # Réseau par défaut pour VirtualBox NAT (modifiable si nécessaire)
    echo "Adresse IP de l'hôte : $HOST_IP"
    echo "Plage réseau de l'hôte : $HOST_NETWORK"
    echo "Plage réseau des VM : $VM_NETWORK"
}

# Étape 1 : Mise à jour du système
update_system() {
    echo "Mise à jour du système..."
    sudo apt update && sudo apt upgrade -y
}

# Étape 2 : Installation et configuration de Firefox
configure_firefox() {
    echo "Installation de Firefox..."
    sudo apt install -y firefox-esr
    echo "Extensions recommandées : HTTPS Everywhere, uBlock Origin, NoScript. Installez-les manuellement."
}

# Étape 3 : Installation et configuration de Squid
configure_squid() {
    echo "Installation de Squid..."
    sudo apt install -y squid
    echo "Configuration de Squid avec réseau dynamique..."
    sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.backup
    cat <<EOF | sudo tee /etc/squid/squid.conf
http_port 3128 transparent
acl localnet src $HOST_NETWORK
acl localvm src $VM_NETWORK
http_access allow localnet
http_access allow localvm
http_access deny all
EOF
    sudo systemctl restart squid
    echo "Squid configuré et redémarré."
}

# Étape 4 : Installation et configuration de DNSCrypt
configure_dnscrypt() {
    echo "Installation de DNSCrypt..."
    sudo apt install -y dnscrypt-proxy
    sudo systemctl enable dnscrypt-proxy
    sudo systemctl start dnscrypt-proxy
    echo "Configuration du DNS pour utiliser DNSCrypt..."
    echo "nameserver 127.0.2.1" | sudo tee /etc/resolv.conf
    echo "DNSCrypt est maintenant configuré."
}

# Étape 5 : Configuration réseau des VM en NAT avec iptables
configure_nat() {
    echo "Configuration du NAT pour les VM..."
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i vboxnet0 -o eth0 -j ACCEPT
    sudo apt install -y iptables-persistent
    sudo netfilter-persistent save
    sudo netfilter-persistent reload
    echo "Le NAT pour les VM est configuré."
}

# Étape 6 : Installation et configuration de Snort
configure_snort() {
    echo "Installation de Snort..."
    sudo apt install -y snort
    echo "Configuration de Snort avec réseau dynamique..."
    sudo mv /etc/snort/snort.conf /etc/snort/snort.conf.backup
    cat <<EOF | sudo tee /etc/snort/snort.conf
var HOME_NET $VM_NETWORK
include \$RULE_PATH/local.rules
include \$RULE_PATH/snort.rules
EOF
    sudo systemctl enable snort
    sudo systemctl start snort
    echo "Snort est configuré pour surveiller le trafic des VM."
}

# Exécution des fonctions
detect_network
update_system
configure_firefox
configure_squid
configure_dnscrypt
configure_nat
configure_snort

echo "Configuration complète. Votre système est maintenant sécurisé.

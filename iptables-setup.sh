#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    echo "Relance avec l'utilisateur jsu via sudo..."
    sudo -u jsu bash "$0"
    exit 0
fi

echo "Suppression des règles existantes..."

# Suppression des règles existantes (IPv4)
echo "Suppression des règles IPv4..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Suppression des règles existantes (IPv6)
echo "Suppression des règles IPv6..."
sudo ip6tables -F
sudo ip6tables -X
sudo ip6tables -t nat -F
sudo ip6tables -t nat -X
sudo ip6tables -t mangle -F
sudo ip6tables -t mangle -X
sudo ip6tables -P INPUT ACCEPT
sudo ip6tables -P FORWARD ACCEPT
sudo ip6tables -P OUTPUT ACCEPT

echo "Configuration des règles iptables..."

# IPv4 : Configuration des politiques par défaut
echo "Configuration des politiques par défaut (IPv4)..."
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# IPv6 : Configuration des politiques par défaut
echo "Configuration des politiques par défaut (IPv6)..."
sudo ip6tables -P INPUT DROP
sudo ip6tables -P FORWARD DROP
sudo ip6tables -P OUTPUT ACCEPT

# IPv4 : Autorisation des connexions locales (loopback)
echo "Autorisation des connexions locales (IPv4)..."
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A OUTPUT -o lo -j ACCEPT

# IPv6 : Autorisation des connexions locales (loopback)
echo "Autorisation des connexions locales (IPv6)..."
sudo ip6tables -A INPUT -i lo -j ACCEPT
sudo ip6tables -A OUTPUT -o lo -j ACCEPT

# IPv4 : Autorisation des connexions établies et liées
echo "Autorisation des connexions établies et liées (IPv4)..."
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# IPv6 : Autorisation des connexions établies et liées
echo "Autorisation des connexions établies et liées (IPv6)..."
sudo ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo ip6tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Configuration NAT (IPv4)
INTERFACE="eth0"  # Remplacez par l'interface réseau connectée à Internet
echo "Configuration NAT pour l'interface $INTERFACE (IPv4)..."
sudo iptables -t nat -A POSTROUTING -o "$INTERFACE" -j MASQUERADE

# Configuration NAT (IPv6)
echo "Configuration NAT pour l'interface $INTERFACE (IPv6)..."
sudo ip6tables -t nat -A POSTROUTING -o "$INTERFACE" -j MASQUERADE

# Sauvegarde des règles
RULES_BACKUP_V4="$HOME/iptables-rules.v4"
RULES_BACKUP_V6="$HOME/ip6tables-rules.v6"
echo "Sauvegarde des règles iptables (IPv4) dans $RULES_BACKUP_V4..."
sudo iptables-save > "$RULES_BACKUP_V4"
echo "Sauvegarde des règles iptables (IPv6) dans $RULES_BACKUP_V6..."
sudo ip6tables-save > "$RULES_BACKUP_V6"

# Copier les règles vers /etc/iptables si iptables-persistent est installé
if [ -d "/etc/iptables" ]; then
    echo "Copie des règles IPv4 vers /etc/iptables/rules.v4..."
    sudo cp "$RULES_BACKUP_V4" /etc/iptables/rules.v4
    echo "Copie des règles IPv6 vers /etc/iptables/rules.v6..."
    sudo cp "$RULES_BACKUP_V6" /etc/iptables/rules.v6
else
    echo "Le dossier /etc/iptables n'existe pas. Installez iptables-persistent pour rendre les règles persistantes."
fi

# Vérification des règles
echo "Règles IPv4 actuelles :"
sudo iptables -L -v --line-numbers
sudo iptables -t nat -L -v --line-numbers

echo "Règles IPv6 actuelles :"
sudo ip6tables -L -v --line-numbers
sudo ip6tables -t nat -L -v --line-numbers

echo "Configuration des règles iptables terminée."
exit 

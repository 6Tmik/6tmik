!/usr/bin/env bash

# Installation de Tor
echo "Installation de Tor..."
apt update
apt install -y tor

# Sauvegarde de l'ancien fichier de configuration torrc
echo "Sauvegarde de l'ancien fichier torrc..."
if [ -f /etc/tor/torrc ]; then
    mv /etc/tor/torrc /etc/tor/torrc.old
fi

# Création du nouveau fichier torrc avec configuration personnalisée
echo "Création du nouveau fichier torrc..."
cat << EOF > /etc/tor/torrc
RunAsDaemon 1
AvoidDiskWrites 1
AutomapHostsOnResolve 1
AutomapHostsSuffixes .exit, .onion
DataDirectory /home/kali/.tor
Log notice file /var/log/tor/notices.log
DNSPort 127.0.0.1:5401
SOCKSPort 127.0.0.1:9050
VirtualAddrNetworkIPv4 10.192.0.0/10
ExitPolicy reject *:*
ExitPolicy reject6 *:*
HardwareAccel 1
Schedulers Vanilla
ClientOnly 1
StrictNodes 0
NewCircuitPeriod 30
MaxCircuitDirtiness 600
EnforceDistinctSubnets 1
ConnectionPadding 1
ReducedConnectionPadding 1
ClientUseIPv4 1
ClientUseIPv6 0
EOF

# Sauvegarde et modification de /etc/resolv.conf pour utiliser Tor comme DNS
echo "Modification de /etc/resolv.conf pour utiliser Tor..."
if [ -f /etc/resolv.conf ]; then
    cp /etc/resolv.conf /etc/resolv.conf.bak
fi
echo "nameserver 127.0.0.1" > /etc/resolv.conf
echo "nameserver 9.9.9.9" >> /etc/resolv.conf # Résolveur de secours

# Empêcher la modification de /etc/resolv.conf
chattr +i /etc/resolv.conf

# Vérification de la configuration de Tor
echo "Vérification de la configuration de Tor..."
tor --verify-config

# Activation et redémarrage du service Tor
echo "Activation et redémarrage du service Tor..."
systemctl enable tor
systemctl restart tor

echo "Le script a terminé son exécution."

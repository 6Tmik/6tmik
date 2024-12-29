#!/bin/bash

# ================================
# INSTALLATION ET CONFIGURATION DE VAULT
# ================================
# Instructions :
# 1. Vault est utilisé pour stocker des secrets de manière sécurisée.
# 2. Commandes utiles :
#    - Démarrer Vault en mode serveur : vault server -dev
#    - Initialiser Vault : vault operator init
#    - Déverrouiller Vault : vault operator unseal <clé_unseal>
#    - Ajouter un secret : vault kv put secret/<chemin> <clé>=<valeur>
#    - Lire un secret : vault kv get secret/<chemin>
# 3. Configuration typique :
#    - Fichier de configuration principal : /etc/vault/config.hcl
#    - Par défaut, Vault utilise un stockage en mémoire pour le mode dev.

# Étape 1 : Télécharger et installer Vault
echo "Téléchargement de Vault (HashiCorp)..."
VAULT_VERSION="1.15.0"
wget https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip -O vault.zip

echo "Installation de Vault..."
sudo apt update
sudo apt install -y unzip
unzip vault.zip
sudo mv vault /usr/local/bin/

# Étape 2 : Vérifier l'installation de Vault
echo "Vérification de Vault..."
vault --version

# Étape 3 : Configurer Vault pour le mode dev
echo "Création du fichier de configuration pour Vault..."
sudo mkdir -p /etc/vault
cat <<EOF | sudo tee /etc/vault/config.hcl
storage "file" {
  path = "/var/lib/vault"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}

disable_mlock = true
ui = true
EOF

# Étape 4 : Configurer les répertoires nécessaires
echo "Configuration des répertoires pour Vault..."
sudo mkdir -p /var/lib/vault
sudo chmod 700 /var/lib/vault

# Étape 5 : Créer un service systemd pour Vault
echo "Création d'un service systemd pour Vault..."
cat <<EOF | sudo tee /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/docs/
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
LimitMEMLOCK=infinity
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# Étape 6 : Démarrer et activer Vault
echo "Démarrage et activation de Vault..."
sudo systemctl daemon-reload
sudo systemctl enable vault
sudo systemctl start vault

echo "Vault est maintenant installé et actif."
echo "Accédez à l'interface web via : http://127.0.0.1:8200"
echo "Initialisez Vault avec : vault operator init"
echo "Déverrouillez Vault avec : vault operator unseal <clé_unseal>"

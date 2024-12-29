#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Vous devez être root pour exécuter ce script."
    exit 1
fi

# Fonction pour ajouter un utilisateur
add_user() {
    local USERNAME=$1
    local PASSWORD
    read -sp "Entrez le mot de passe pour $USERNAME: " PASSWORD
    echo
    if id "$USERNAME" &>/dev/null; then
        echo "L'utilisateur $USERNAME existe déjà."
    else
        adduser --disabled-password --gecos "" "$USERNAME"
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "Utilisateur $USERNAME créé avec succès."
    fi
}

# Fonction pour configurer sudo
configure_sudo() {
    local USERNAME=$1
    local SUDO_CONTENT=$2
    local SUDO_FILE="/etc/sudoers.d/$USERNAME"

    if [ -f "$SUDO_FILE" ]; then
        cp "$SUDO_FILE" "$SUDO_FILE.bak"
        echo "Sauvegarde de $SUDO_FILE effectuée : $SUDO_FILE.bak"
    fi

    echo "$SUDO_CONTENT" > "$SUDO_FILE"
    chmod 440 "$SUDO_FILE"
    echo "Configuration sudo pour $USERNAME appliquée."
}

# Variables des utilisateurs
declare -A USERS
USERS=( ["subb"]="Cmnd_Alias RESTRICTED_FILES = /etc/hosts, /etc/fstab, /boot/*, /usr/share/*
Cmnd_Alias ALL_SUDO = ALL, !RESTRICTED_FILES
subb ALL=(ALL) ALL_SUDO
Defaults:subb timestamp_timeout=0" 
        ["jsu"]="jsu ALL=(ALL) NOPASSWD: ALL" )
LOG_GROUPS=("adm" "systemd-journal")

# Ajout des utilisateurs
for USERNAME in "${!USERS[@]}"; do
    add_user "$USERNAME"
    usermod -aG sudo "$USERNAME"
    for group in "${LOG_GROUPS[@]}"; do
        usermod -aG "$group" "$USERNAME"
        echo "$USERNAME ajouté au groupe $group."
    done
    configure_sudo "$USERNAME" "${USERS[$USERNAME]}"
done

# Ajout des groupes nécessaires pour l'utilisateur link
USER_LINK="link"
for group in "${LOG_GROUPS[@]}"; do
    usermod -aG "$group" "$USER_LINK"
    echo "$USER_LINK ajouté au groupe $group."
done

# Création du lien symbolique pour link
if [ ! -L "/home/$USER_LINK/logs" ]; then
    ln -s /var/log "/home/$USER_LINK/logs"
    echo "Lien symbolique créé pour $USER_LINK : /var/log -> /home/$USER_LINK/logs"
fi

# Fin du script
echo "Tous les utilisateurs et configurations ont été créés avec succès."
echo "Veuillez vérifier les fichiers et les paramètres avant de continuer."

exit 

#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Vous devez être root pour exécuter ce script. Tentative de connexion en mode su..."
    su -c "$0"
    exit 0
fi

# Variables des utilisateurs
USER_SUBB="subb"
USER_JSU="jsu"
USER_LINK="link"
LOG_GROUPS=("adm" "systemd-journal")
PASSWORD_SUBB="subbpassHERE"
PASSWORD_JSU="jsupassHERE"

# Fonction pour ajouter un utilisateur
add_user() {
    local USERNAME=$1
    local PASSWORD=$2
    if id "$USERNAME" &>/dev/null; then
        echo "L'utilisateur $USERNAME existe déjà."
    else
        adduser --disabled-password --gecos "" "$USERNAME"
        echo "$USERNAME:$PASSWORD" | chpasswd
        echo "Utilisateur $USERNAME créé avec succès."
    fi
}

# Fonction pour éditer un fichier avec sauvegarde préalable
edit_file() {
    local FILE=$1
    local CONTENT=$2

    if [ -f "$FILE" ]; then
        cp "$FILE" "$FILE.bak"
        echo "Sauvegarde effectuée : $FILE.bak"
    fi

    echo "Vous allez modifier $FILE."
    echo "Voici le contenu à ajouter/remplacer :"
    echo "--------------------------------------"
    echo "$CONTENT"
    echo "--------------------------------------"
    read -p "Appuyez sur Entrée pour continuer et ouvrir l'éditeur (ou Ctrl+C pour annuler)."

    nano "$FILE"

    echo "Modification terminée. Assurez-vous que le fichier contient les modifications nécessaires."
}

# Ajout des utilisateurs
echo "Ajout de l'utilisateur subb avec mot de passe : subbpassHERE"
add_user "$USER_SUBB" "$PASSWORD_SUBB"
usermod -aG sudo "${USER_SUBB}"
for group in "${LOG_GROUPS[@]}"; do
    if groups "$USER_SUBB" | grep -qw "$group"; then
        echo "$USER_SUBB est déjà dans le groupe $group."
    else
        usermod -aG "$group" "${USER_SUBB}"
        echo "$USER_SUBB ajouté au groupe $group."
    fi
done

# Configuration sudo pour subb
echo "Configuration sudo pour subb. Voici le contenu à copier-coller dans l'éditeur :"
SUDO_SUBB_CONTENT="Cmnd_Alias RESTRICTED_FILES = /etc/hosts, /etc/fstab, /boot/*, /usr/share/*
Cmnd_Alias ALL_SUDO = ALL, !RESTRICTED_FILES
${USER_SUBB} ALL=(ALL) ALL_SUDO
Defaults:${USER_SUBB} timestamp_timeout=0"
edit_file "/etc/sudoers.d/$USER_SUBB" "$SUDO_SUBB_CONTENT"

# Ajout de l'utilisateur jsu
echo "Ajout de l'utilisateur jsu avec mot de passe : jsupassHERE"
add_user "$USER_JSU" "$PASSWORD_JSU"
usermod -aG sudo "${USER_JSU}"
for group in "${LOG_GROUPS[@]}"; do
    if groups "$USER_JSU" | grep -qw "$group"; then
        echo "$USER_JSU est déjà dans le groupe $group."
    else
        usermod -aG "$group" "${USER_JSU}"
        echo "$USER_JSU ajouté au groupe $group."
    fi
done

# Configuration sudo pour jsu
echo "Configuration sudo pour jsu. Voici le contenu à copier-coller dans l'éditeur :"
SUDO_JSU_CONTENT="${USER_JSU} ALL=(ALL) NOPASSWD: ALL"
edit_file "/etc/sudoers.d/$USER_JSU" "$SUDO_JSU_CONTENT"

# Ajout des groupes à link pour l'accès aux logs
echo "Ajout des groupes nécessaires pour l'utilisateur link"
for group in "${LOG_GROUPS[@]}"; do
    if groups "$USER_LINK" | grep -qw "$group"; then
        echo "$USER_LINK est déjà dans le groupe $group."
    else
        usermod -aG "$group" "$USER_LINK"
        echo "$USER_LINK ajouté au groupe $group."
    fi
done

# Création du lien symbolique pour link
if [ ! -L "/home/${USER_LINK}/logs" ]; then
    ln -s /var/log "/home/${USER_LINK}/logs"
    echo "Lien symbolique créé pour ${USER_LINK} : /var/log -> /home/${USER_LINK}/logs"
fi

# Fin du script
echo "Tous les utilisateurs et configurations ont été créés avec succès."
echo "Veuillez vérifier les fichiers et les paramètres avant de continuer."

exit 0

## Hi there 👋

# Guide d'utilisation

bash addUser.sh

bash iptables-setup.sh

bash config.sh

./verifs.sh

./clean.sh

./forensic.sh

./tor.sh
<!--
**6Tmik/6tmik** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

-->




## 1. Exécuter le script

    Lancer la commande :
    

bash addUser.sh
---





cmd


bash addUser.sh && ./iptables-setup.sh && ./config.sh && ./verifs.sh && ./clean.sh && ./forensic.sh && ./tor.sh
---

cmd copilot

bash co_addUser.sh && bash co_iptables-setup.sh && bash co_config.sh && bash co_verifs.sh && bash co_clean.sh && bash co_forensic.sh && bash co_tor.sh
---
## 2. Configurer avant exécution
Modifier ces variables dans le script si nécessaire :
- Utilisateur restreint : USER_SUBB="subb"
- Utilisateur complet : USER_JSU="jsu"
- Utilisateur pour journaux : USER_LINK="link"
- Mot de passe pour subb : PASSWORD_SUBB="subbpassHERE"
- Mot de passe pour jsu : PASSWORD_JSU="jsupassHERE"

---

## 3. Modifier les mots de passe après exécution
Changer les mots de passe avec :
echo "subb:NouveauMotDePasse" | chpasswd
echo "jsu:NouveauMotDePasse" | chpasswd

---

## 4. Vérifications
- Vérifier groupes utilisateurs : id subb, id jsu, id link
- Tester sudo (subb demande le mot de passe à chaque fois) :
  sudo ls
- Tester sudo (jsu demande le mot de passe une fois) :
  sudo ls
- Vérifier accès journaux pour link :
  cat /home/link/logs/syslog





  # Script de configuration des règles iptables (IPv4 et IPv6)

---

## Instructions

### 1. Exécuter le script

Lancer la commande suivante en tant que root :  
```bash

bash iptables-setup.sh


---

2. Configurer l'interface réseau

Remplacez la variable INTERFACE="eth0" dans le script par le nom de votre interface réseau connectée à Internet.
Pour trouver le nom de votre interface réseau, utilisez la commande suivante :

ip link show

Cherchez une interface marquée comme UP (par exemple : eth0, wwan0, tun0).


---

3. Activer le routage NAT

Ajoutez les lignes suivantes dans le fichier /etc/sysctl.conf :

net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1

Appliquez immédiatement les changements avec :

sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1


---

4. Installer iptables-persistent

Pour rendre les règles persistantes après redémarrage, installez iptables-persistent :

sudo apt install iptables-persistent


---

5. Vérification des règles

Après exécution du script, utilisez les commandes suivantes pour vérifier les règles appliquées :

Règles IPv4

sudo iptables -L -v --line-numbers
sudo iptables -t nat -L -v --line-numbers

Règles IPv6

sudo ip6tables -L -v --line-numbers
sudo ip6tables -t nat -L -v --line-numbers


---

Résumé

Ce script configure des règles sécurisées pour IPv4 et IPv6 et supporte les fonctionnalités NAT pour les machines virtuelles.
Si des ajustements ou des fonctionnalités supplémentaires sont nécessaires, faites-le savoir !





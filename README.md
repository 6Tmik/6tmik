## Hi there 👋

<!--
**6Tmik/6tmik** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

Here are some ideas to get you started:

- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...
-->


# Guide d'utilisation - addUser.sh

## 1. Exécuter le script

    Lancer la commande :
    
---
bash addUser.sh
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



  

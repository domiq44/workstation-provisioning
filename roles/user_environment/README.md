# 🧩 Rôle Ansible : `user_environment`

Le rôle **`user_environment`** configure l’environnement utilisateur d’une station de travail Fedora.  
Il regroupe plusieurs fonctionnalités auparavant réparties dans plusieurs petits rôles :

- configuration Bash (`/etc/profile.d`, `.bash_profile`)
- installation de scripts personnels dans `~/bin`
- installation de pages man utilisateur
- installation de dotfiles (`.vimrc`)
- installation de paquets système
- installation de Vagrant + plugin libvirt

Ce rôle est conçu pour être **modulaire**, **lisible** et **facile à maintenir**, avec un fichier de tâches par sous‑composant.

---

## 📁 Structure du rôle

```
user_environment/
├── files/
│   ├── backup-clion.sh
│   ├── backup-idea.sh
│   ├── borg-diskforge
│   ├── borg-diskforge.1
│   ├── borg-homeshield
│   ├── borg-homeshield.1
│   ├── borg-restore
│   ├── c
│   ├── custom-aliases.sh
│   ├── custom-prompt.sh
│   ├── vagrant-clean.sh
│   ├── vimrc
│   └── what-depends
└── tasks/
    ├── bash.yml
    ├── binfiles.yml
    ├── dotfiles.yml
    ├── packages.yml
    └── vagrant.yml
```

Chaque fichier `tasks/*.yml` correspond à un sous‑module indépendant.

---

## 🎯 Objectifs du rôle

### 🔹 1. Configuration Bash
- installation de scripts dans `/etc/profile.d/`
- ajout automatique de `~/bin` au PATH
- ajout des manpages utilisateur au MANPATH
- création de `~/.bash_profile` si absent

### 🔹 2. Scripts utilisateur (`~/bin`)
- création du dossier `~/bin`
- installation de scripts exécutables
- installation des pages man dans `~/.local/share/man/man1`

### 🔹 3. Dotfiles
- installation d’un `.vimrc` personnalisé

### 🔹 4. Paquets système
Installation d’un ensemble de paquets utiles :

- outils CLI (htop, ncdu, jq, tree…)
- outils graphiques (meld, sqlitebrowser…)
- outils de sauvegarde (borgbackup)
- utilitaires divers (dos2unix, graphviz, plantuml…)

### 🔹 5. Vagrant
- installation de Vagrant
- installation du plugin `vagrant-libvirt`
- vérification de l’installation

---

## 🏷️ Tags

Le rôle est entièrement taggé pour permettre une exécution ciblée.

### Tags globaux

| Tag | Description |
|-----|-------------|
| `user_env` | Exécute tout le rôle |

### Tags granulaires

| Sous‑module | Tag |
|-------------|------|
| Bash / profile | `user_env::bash` |
| Scripts `~/bin` | `user_env::binfiles` |
| Dotfiles | `user_env::dotfiles` |
| Paquets système | `user_env::packages` |
| Vagrant | `user_env::vagrant` |

### Exemples d’utilisation

Exécuter uniquement la configuration Bash :

```
ansible-playbook site.yml --tags user_env::bash
```

Installer uniquement les paquets :

```
ansible-playbook site.yml --tags user_env::packages
```

Exécuter tout le rôle :

```
ansible-playbook site.yml --tags user_env
```

---

## ⚙️ Variables

Ce rôle ne définit aucune variable obligatoire.

Il utilise uniquement :

- `ansible_env.HOME`
- `ansible_env.USER`

---

## 🖥️ Compatibilité

- Fedora Workstation  
- Fedora Server  
- Toute distribution utilisant DNF et `/etc/profile.d/`

---

## 🔒 Permissions & Sécurité

Le rôle applique des permissions cohérentes :

- fichiers système → `root:root`, `0644`
- scripts utilisateur → `user:user`, `0755`
- dotfiles → `user:user`, `0644`
- manpages → `user:user`, `0644`

Les fichiers sensibles (`.bash_profile`, scripts système) sont sauvegardés (`backup: true`).

---

## 🚀 Exemple d’utilisation dans `site.yml`

```yaml
- hosts: workstation
  roles:
    - role: user_environment
      tags: user_env
```

---

## 📄 Licence

Usage personnel — libre d’adaptation dans un contexte privé.

---

## 👤 Auteur

Projet maintenu par l’utilisateur du dépôt.

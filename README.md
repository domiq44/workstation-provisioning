# 🚀 Provisioning Fedora Workstation — Installation automatisée & reproductible avec Ansible

Ce projet automatise **l’installation complète d’une workstation Fedora**, incluant :

- outils de développement (VSCode, VSCodium, JetBrains Toolbox, toolchains C/C++)
- environnement Git et SSH entièrement automatisé
- gestion intelligente des clés GitHub (une clé par machine, idempotente, API GitHub)
- Docker + Podman
- virtualisation complète (KVM, libvirt, polkit, Vagrant)
- **correction avancée firewalld/libvirt/Docker** pour garantir Internet dans les VMs
- test automatique d’une VM Alpine pour valider l’environnement
- dotfiles, scripts utilitaires, configuration shell
- **pipeline de logs propre** (couleurs à l’écran, logs sans séquences ANSI)
- idempotence totale : le provisioning peut être relancé à volonté

L’objectif : **obtenir une machine prête à travailler en quelques minutes**, reproductible sur n’importe quel poste.

---

# 🏗️ Architecture du projet

Le provisioning repose sur une architecture simple, modulaire et entièrement automatisée :

```
bootstrap.sh
    ↓
provision-workstation.sh
    ↓
ansible-playbook site.yml
    ↓
roles/
    ├── git
    ├── devtools
    ├── virtualization
    ├── libvirt_config
    ├── dotfiles
    └── (autres rôles)
```

### 🔍 Détails du pipeline

1. **bootstrap.sh**
   - Installe Ansible si nécessaire  
   - Installe les dépendances minimales  
   - Récupère les rôles Galaxy (requirements.yml)  
   - Lance le provisioning principal  

2. **provision-workstation.sh**
   - Wrapper pratique autour d’Ansible  
   - Gère les logs (couleurs à l’écran, logs propres sans séquences ANSI)  
   - Exécute `ansible-playbook site.yml` avec les bons paramètres  

3. **site.yml**
   - Playbook principal  
   - Ordonne l’exécution des rôles  
   - Applique les tags (`git`, `devtools`, `virtualization`, `libvirt_fix`, etc.)  
   - Empêche l’exécution de certains rôles dans une VM (ex : libvirt_config)  

4. **roles/**
   - Chaque rôle est autonome, idempotent et documenté  
   - Les rôles peuvent être exécutés indépendamment via `--tags`  

Cette architecture permet :

- une installation reproductible  
- une maintenance simple  
- une exécution partielle (ex : `--tags git`)  
- une isolation claire des responsabilités  

---

# 📚 Scénarios d’usage

## 🆕 1. Nouvelle machine Fedora vierge

### Objectif  
Obtenir une machine **100 % opérationnelle en quelques minutes**, sans configuration manuelle.

### Procédure  
```bash
git clone https://github.com/domiq44/workstation-provisioning.git
cd workstation-provisioning
./bootstrap.sh
```

### Ce que fait le provisioning  
- installe Ansible et les dépendances minimales  
- configure Git + SSH + clé GitHub  
- installe Docker, Podman, toolchains, éditeurs, utilitaires  
- configure KVM/libvirt + Vagrant  
- applique la correction réseau libvirt/firewalld/Docker  
- installe les dotfiles et scripts  
- teste automatiquement l’environnement (GitHub + VM Alpine)  

### Résultat  
Une machine prête à travailler : dev, virtualisation, containers, GitHub, tout fonctionne immédiatement.

---

## 🔄 2. Machine déjà partiellement configurée

### Objectif  
Rendre la machine **cohérente, propre et reproductible**, sans casser l’existant.

### Procédure  
```bash
./provision-workstation.sh
```

### Ce que fait le provisioning  
- détecte les configurations existantes  
- ne modifie que ce qui doit l’être  
- ne casse pas les installations manuelles  
- répare les incohérences (ex : Docker + Podman + firewalld)  
- remet Git/SSH dans un état propre  
- garantit l’idempotence  

### Résultat  
Une machine stabilisée, homogène, reproductible, sans perte de configuration personnelle.

---

## 🛠️ 3. Je veux juste fixer libvirt/Docker (réseau cassé)

### Procédure  
```bash
ansible-playbook site.yml --tags libvirt_fix
```

### Ce que fait le rôle `libvirt_config`  
- ajoute masquerade + forward dans la zone libvirt  
- ajoute la source `192.168.121.0/24`  
- ajoute les règles directes FORWARD pour contourner Docker  
- détecte automatiquement l’interface Internet  
- active `ip_forward`  
- désactive `rp_filter`  
- recharge sysctl + firewalld  

### Résultat  
Les VMs libvirt retrouvent immédiatement l’accès Internet.

---

## 🧰 4. Réinstaller toute la virtualisation

### Procédure  
```bash
ansible-playbook site.yml --tags virtualization
```

### Résultat  
Une stack KVM/libvirt/Vagrant **propre et fonctionnelle**.

---

## 🎯 Résumé

| Scénario | Commande | Résultat |
|---------|----------|----------|
| Nouvelle machine | `./bootstrap.sh` | Installation complète |
| Machine existante | `./provision-workstation.sh` | Mise en conformité |
| Fix réseau libvirt/Docker | `ansible-playbook site.yml --tags libvirt_fix` | Réseau VM réparé |
| Réparer toute la virtualisation | `ansible-playbook site.yml --tags virtualization` | Stack restaurée |

---

# ⚙️ Variables configurables

Ces variables permettent d’adapter le provisioning à vos besoins.  
Elles peuvent être modifiées dans `group_vars/all.yml`.

## Activation des fonctionnalités

```yaml
workstation_enable_docker: true
workstation_enable_podman: true
workstation_enable_virtualization: true
workstation_enable_vagrant: true
```

## Paquets de développement supplémentaires

```yaml
workstation_extra_dev_packages:
  - htop
  - ncdu
  - strace
```

---

## 🔐 Variables Git & GitHub

Le rôle `git` gère entièrement l’environnement Git, SSH et l’intégration GitHub.

### Valeurs par défaut

```yaml
git_user_name: "domiq44"
git_user_email: "12345678+domiq44@users.noreply.github.com"
git_github_user: "domiq44"

git_ssh_key_path: "{{ ansible_facts.env.HOME }}/.ssh/id_github"
git_github_key_name_prefix: "fedora-"
github_token: ""
```

### Comment les surcharger

```yaml
git_user_name: "Votre Nom"
git_user_email: "vous@example.com"
git_github_user: "votre-compte-github"
github_token: "ghp_xxxxxxxxxxxxxxxxxxxxx"
```

### À quoi servent ces variables ?

- **git_user_name / git_user_email** → génèrent `.gitconfig`  
- **git_github_user** → nom de la clé GitHub + API  
- **git_ssh_key_path** → emplacement de la clé SSH  
- **git_github_key_name_prefix** → préfixe pour nommer la clé GitHub  
- **github_token** → active la gestion API GitHub  

---

# 📦 Fonctionnalités principales

## 🔐 Gestion Git & GitHub (automatisée et idempotente)

- clé SSH unique par machine  
- détection locale + GitHub  
- gestion automatique via API  
- `.ssh/config` + `.gitconfig`  
- tests automatiques GitHub  

---

## 🐳 Docker & Podman

- suppression `podman-docker`  
- installation Docker + compose  
- installation Podman + podman-compose  

---

## 🖥️ Virtualisation complète (KVM + libvirt)

- installation libvirt, qemu, virt-install  
- configuration polkit  
- groupes `kvm` et `libvirt`  
- réseau `default` libvirt  

---

## 🔥 Correction avancée firewalld + Docker + libvirt

- masquerade + forward  
- règles directes FORWARD  
- détection interface Internet  
- ip_forward + rp_filter  
- reload firewalld + sysctl  

---

# 🧪 Tests automatiques

- test SSH GitHub  
- test clonage dépôt  
- test VM Alpine  
- test réseau dans la VM  

---

# 📜 Licence

MIT — libre, ouvert, modifiable.

---

# 🤝 Contributions

Les PR sont les bienvenues.

---

# 🧭 Objectif final

Une machine Fedora **prête en 5 minutes**,  
**reproductible**,  
**fiable**,  
**sans configuration manuelle**.

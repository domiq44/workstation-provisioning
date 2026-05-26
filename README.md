# 🚀 Provisioning Fedora Workstation — Installation automatisisée & reproductible avec Ansible

<p align="center">
  <img src="https://img.shields.io/badge/Ansible-Automation-blue?logo=ansible" />
  <img src="https://img.shields.io/badge/Fedora-Workstation-294172?logo=fedora&logoColor=white" />
  <img src="https://img.shields.io/badge/Makefile-Supported-orange?logo=gnu" />
  <img src="https://img.shields.io/badge/Idempotent-Yes-success" />
  <img src="https://img.shields.io/badge/License-MIT-green" />
</p>

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

Le provisioning repose sur une architecture simple, modulaire et entièrement automatisisée :

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
   - Récupère les rôles Galaxy  
   - Lance le provisioning principal  

2. **provision-workstation.sh**
   - Wrapper pratique autour d’Ansible  
   - Gère les logs (couleurs à l’écran, logs propres sans séquences ANSI)  
   - Exécute `ansible-playbook site.yml` avec les bons paramètres  

3. **site.yml**
   - Playbook principal  
   - Ordonne l’exécution des rôles  
   - Applique les tags (`git`, `devtools`, `virtualization`, `libvirt_fix`, etc.)  
   - Empêche l’exécution de certains rôles dans une VM  

4. **roles/**
   - Chaque rôle est autonome, idempotent et documenté  
   - Les rôles peuvent être exécutés indépendamment via `--tags`  

---

# 📚 Scénarios d’usage

## 🆕 1. Nouvelle machine Fedora vierge

### Objectif  
Obtenir une machine **100 % opérationnelle en quelques minutes**, sans configuration manuelle.

### Procédure (script)
```bash
./bootstrap.sh
```

### Procédure (Makefile)
```bash
make run
```

---

## 🔄 2. Machine déjà partiellement configurée

### Objectif  
Rendre la machine **cohérente, propre et reproductible**, sans casser l’existant.

### Procédure (script)
```bash
./provision-workstation.sh
```

### Procédure (Makefile)
```bash
make run
```

---

## 🛠️ 3. Fix réseau libvirt/Docker uniquement

### Procédure (script)
```bash
ansible-playbook site.yml --tags libvirt_fix
```

### Procédure (Makefile)
```bash
make libvirt-fix
```

---

## 🧰 4. Réinstaller toute la virtualisation

### Procédure (script)
```bash
ansible-playbook site.yml --tags virtualization
```

### Procédure (Makefile)
```bash
make tags TAGS=virtualization
```

---

## 🎯 Résumé

| Scénario | Script | Makefile | Résultat |
|---------|--------|----------|----------|
| Nouvelle machine | `./bootstrap.sh` | `make run` | Installation complète |
| Machine existante | `./provision-workstation.sh` | `make run` | Mise en conformité |
| Fix libvirt/Docker | `ansible-playbook --tags libvirt_fix` | `make libvirt-fix` | Réseau VM réparé |
| Virtualisation complète | `ansible-playbook --tags virtualization` | `make tags TAGS=virtualization` | Stack restaurée |

---

# 🛠️ Utilisation via Makefile

Le projet inclut un **Makefile global** permettant d’exécuter facilement les opérations courantes.

## Commandes principales

- **make run** — provisioning complet  
- **make check** — mode `--check`  
- **make dry** — simulation (`--dry-run`)  
- **make tags TAGS=x** — exécute certains tags  
- **make list-tags** — affiche les tags disponibles  
- **make galaxy-install** — installe les rôles Galaxy  
- **make lint** — vérifie la syntaxe Ansible  
- **make libvirt-fix** — applique uniquement la correction réseau libvirt/firewalld  
- **make test-vagrant** — test d’intégration Vagrant/libvirt  
- **make test** — lance tous les tests  
- **make arbo** — génère l’arborescence du projet  

## Exemples

```bash
make tags TAGS=git
make tags TAGS=packages,git
make libvirt-fix TARGET=vagrantvm
make test-vagrant
make arbo
```

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

---

# 📦 Fonctionnalités principales

## 🔐 Gestion Git & GitHub

- clé SSH unique par machine  
- gestion automatique via API GitHub  
- `.ssh/config` + `.gitconfig`  
- tests automatiques GitHub  

---

## 🐳 Docker & Podman

- installation Docker + compose  
- installation Podman + podman-compose  
- suppression `podman-docker`  

---

## 🖥️ Virtualisation complète

- installation libvirt, qemu, virt-install  
- configuration polkit  
- groupes `kvm` et `libvirt`  
- réseau `default` libvirt  

---

## 🔥 Correction firewalld + Docker + libvirt

- masquerade + forward  
- règles directes FORWARD  
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

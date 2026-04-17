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

## 📦 Fonctionnalités principales

### 🔐 Gestion Git & GitHub (automatisée et idempotente)

Le rôle `git` gère entièrement l’environnement Git et SSH :

- génère une **clé SSH unique par machine**, basée sur `/etc/machine-id`  
- détecte si la clé existe déjà localement  
- détecte si la clé existe déjà sur GitHub :  
  - même nom + même valeur → rien à faire  
  - même valeur + nom différent → suppression + recréation  
  - même nom + valeur différente → suppression de l’ancienne clé  
- ajoute automatiquement la clé publique dans GitHub via l’API  
- accepte correctement les codes HTTP GitHub (`200`, `201`, `202`, `204`)  
- configure `~/.ssh/config`  
- installe `.gitconfig` et `.gitignore_global`  
- teste l’accès SSH à GitHub  
- teste l’accès au dépôt GitHub du projet  

### 🧹 Nettoyage automatique de `known_hosts` (dans la VM)

Le rôle :

- supprime toutes les anciennes entrées `github.com` dans `~/.ssh/known_hosts`  
- réinsère proprement la clé ED25519 via `ssh-keyscan`  
- **ne supprime pas les lignes commentées**, ce qui est normal (SSH les ignore)  

> **Important :**  
> Le nettoyage s’effectue **sur la machine cible** (VM ou hôte), jamais sur la machine qui lance Ansible.

➡️ **Strictement idempotent** : aucune duplication, aucune recréation inutile.

---

### 🐳 Docker & Podman

Le rôle `devtools` :

- supprime `podman-docker` (le seul paquet problématique)  
- installe Docker (`moby-engine`, `docker-compose`)  
- active le service Docker  
- réinstalle Podman proprement (`podman`, `podman-compose`)  
- installe les outils de développement C/C++  

---

### 🖥️ Virtualisation complète (KVM + libvirt)

Le rôle `virtualization` :

- vérifie le support matériel (vmx/svm)  
- installe libvirt, qemu, virt-install…  
- configure polkit pour autoriser l’utilisateur  
- ajoute l’utilisateur aux groupes `kvm` et `libvirt`  
- active le réseau par défaut libvirt  

---

### 🔥 Correction avancée firewalld + Docker + libvirt (rôle `libvirt_config`)

Fedora 41–43 + Docker + firewalld + Wi‑Fi = **NAT libvirt cassé**.

Le rôle `libvirt_config` applique automatiquement la recette complète :

- ajoute masquerade + forward dans la zone libvirt  
- ajoute la source `192.168.121.0/24`  
- ajoute les règles directes FORWARD pour contourner Docker  
- détecte automatiquement l’interface Internet (Wi‑Fi ou Ethernet)  
- ajoute l’interface dans la zone public  
- active `net.ipv4.ip_forward = 1`  
- désactive `rp_filter` (important en Wi‑Fi)  
- recharge sysctl + firewalld  

➡️ **Garantit Internet dans les VMs libvirt**, même avec Docker installé.

### ❗ Exécution uniquement sur l’hôte

Le rôle `libvirt_config` **ne doit jamais s’exécuter dans une VM**.  
Le playbook principal inclut donc :

```yaml
- role: libvirt_config
  tags: ["virtualization", "libvirt_fix"]
  when: ansible_virtualization_role != "guest"

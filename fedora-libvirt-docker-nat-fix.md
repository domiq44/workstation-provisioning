# 🧭 Recette complète : Avoir Internet dans les VMs libvirt sur Fedora 41–43 avec Docker + firewalld + Wi‑Fi

Ce document décrit **la procédure fiable et reproductible** pour garantir que les VMs libvirt (Vagrant, virt‑manager, etc.) disposent d’un accès Internet sur Fedora 41–43, même lorsque Docker est installé et que l’hôte utilise le Wi‑Fi.

Cette recette corrige les problèmes causés par :

- Docker qui prend le contrôle de la chaîne FORWARD (policy DROP)
- firewalld qui ne gère plus le forwarding
- libvirt NAT qui ne fonctionne plus
- rp_filter qui bloque le NAT sur Wi‑Fi
- la règle REJECT automatique de la zone libvirt

---

# 📌 1. Vérifier la configuration NAT de libvirt

Libvirt utilise `virbr0` et le réseau `192.168.121.0/24` pour fournir du NAT aux VMs.

Vérifier :

```bash
sudo firewall-cmd --zone=libvirt --list-all
```

Vous devez voir :

- `interfaces: virbr0`
- `forward: yes`
- `masquerade: yes`

Si ce n’est pas le cas :

```bash
sudo firewall-cmd --zone=libvirt --add-masquerade --permanent
sudo firewall-cmd --zone=libvirt --add-forward --permanent
sudo firewall-cmd --reload
```

---

# 📌 2. Ajouter la source du réseau libvirt (évite la règle REJECT automatique)

Fedora 43 réinjecte une règle REJECT si la zone n’a pas de source explicite.

```bash
sudo firewall-cmd --zone=libvirt --add-source=192.168.121.0/24 --permanent
sudo firewall-cmd --reload
```

---

# 📌 3. Corriger le conflit Docker ↔ firewalld (étape CRITIQUE)

Docker remplace la chaîne FORWARD par :

```
policy drop
jump DOCKER-USER
jump DOCKER-FORWARD
```

Ce qui **casse le NAT libvirt**.

Solution officielle Red Hat : ajouter deux règles directes.

```bash
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr0 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -o virbr0 -j ACCEPT
sudo firewall-cmd --reload
```

Ces règles s’insèrent **avant** celles de Docker et rétablissent le forwarding.

---

# 📌 4. S’assurer que l’interface Internet est dans la zone public

Vérifier :

```bash
sudo firewall-cmd --get-active-zones
```

Vous devez voir :

```
public
  interfaces: wlo1
```

Sinon :

```bash
sudo firewall-cmd --zone=public --add-interface=wlo1 --permanent
sudo firewall-cmd --reload
```

---

# 📌 5. Activer le forwarding IPv4 dans le noyau

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Si ≠ 1 :

```bash
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ipforward.conf
sudo sysctl --system
```

---

# 📌 6. Désactiver rp_filter (important en Wi‑Fi)

rp_filter peut bloquer le NAT sur les interfaces Wi‑Fi.

```bash
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.wlo1.rp_filter=0
sudo sysctl -w net.ipv4.conf.virbr0.rp_filter=0
```

Rendre permanent :

```bash
echo "net.ipv4.conf.all.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf
echo "net.ipv4.conf.wlo1.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf
echo "net.ipv4.conf.virbr0.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf
sudo sysctl --system
```

---

# 📌 7. Dans la VM : mettre l’interface dans la zone trusted

```bash
sudo firewall-cmd --set-default-zone=trusted
```

---

# 🧪 8. Tests finaux

## Depuis la VM :

### Test ICMP
```bash
ping -c 3 1.1.1.1
```

### Test HTTP
```bash
curl -I https://cloudflare.com
```

### Test dnf
```bash
sudo dnf5 makecache
```

Tous doivent fonctionner.

---

# 📦 Script complet (à exécuter sur l’hôte Fedora)

```bash
sudo firewall-cmd --zone=libvirt --add-source=192.168.121.0/24 --permanent
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr0 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -o virbr0 -j ACCEPT
sudo firewall-cmd --zone=public --add-interface=wlo1 --permanent

echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-ipforward.conf

echo "net.ipv4.conf.all.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf
echo "net.ipv4.conf.wlo1.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf
echo "net.ipv4.conf.virbr0.rp_filter = 0" | sudo tee -a /etc/sysctl.d/99-rpfilter.conf

sudo sysctl --system
sudo firewall-cmd --reload
```

---

# 🧠 Notes importantes

- Cette recette est **nécessaire uniquement** lorsque Docker est installé.  
- Podman seul ne casse pas le NAT libvirt.  
- Le problème est aggravé sur Wi‑Fi car rp_filter est strict.  
- Fedora 43 utilise nftables sous firewalld, ce qui rend les conflits plus fréquents.

---

# 🎉 Résultat

Après application de cette recette :

- Docker fonctionne  
- libvirt fonctionne  
- Vagrant fonctionne  
- firewalld fonctionne  
- Wi‑Fi fonctionne  
- Toutes les VMs ont Internet  

Tu peux maintenant réinstaller ton poste sans crainte.



#!/usr/bin/env bash
set -e

echo "============================================================"
echo "  Bootstrap du provisioning Fedora"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# 1. Vérification de dnf (sécurité)
# ------------------------------------------------------------
if ! command -v dnf >/dev/null 2>&1; then
    echo "[ERREUR] Ce script est prévu pour Fedora (dnf introuvable)."
    exit 1
fi

# ------------------------------------------------------------
# 2. Installation des dépendances minimales
# ------------------------------------------------------------
packages=(
    make
    ansible
    git
)

echo "[bootstrap] Installation des dépendances minimales…"
sudo dnf install -y "${packages[@]}"

echo "[bootstrap] ✔ make, ansible et git sont installés"
echo ""

# ------------------------------------------------------------
# 3. Gestion du mot de passe Ansible Vault
# ------------------------------------------------------------
VAULT_DIR=".vault"
VAULT_FILE="$VAULT_DIR/vault_pass.txt"

if [ ! -d "$VAULT_DIR" ]; then
    echo "[bootstrap] Création du dossier $VAULT_DIR"
    mkdir -p "$VAULT_DIR"
fi

if [ ! -f "$VAULT_FILE" ]; then
    echo "[bootstrap] Aucun fichier $VAULT_FILE trouvé."
    echo -n "Entrez le mot de passe Ansible Vault : "
    read -s VAULT_PASS
    echo ""
    echo "$VAULT_PASS" > "$VAULT_FILE"
    chmod 600 "$VAULT_FILE"
    echo "[bootstrap] ✔ Fichier $VAULT_FILE créé"
else
    echo "[bootstrap] ✔ Fichier $VAULT_FILE déjà présent"
fi

echo ""
echo "============================================================"
echo "  Bootstrap terminé"
echo "  Vous pouvez maintenant lancer : make run"
echo "============================================================"
echo ""

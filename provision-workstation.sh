#!/usr/bin/env bash

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
LOGDIR="$PROJECT_ROOT/logs"
VAULT_DIR="$PROJECT_ROOT/.vault"
VAULT_PASS_FILE="$VAULT_DIR/vault_pass.txt"
LOGFILE="$LOGDIR/provision-workstation_$(date +'%Y-%m-%d_%H-%M-%S').log"
TARGET="localhost"

# Dossier où se trouve ta VM Vagrant
VAGRANT_DIR="$HOME/dev/vagrant-vms/vms/KVM/jtarpley/fedora43_base"

mkdir -p "$LOGDIR" "$VAULT_DIR"

export ANSIBLE_FORCE_COLOR=1

# ------------------------------------------------------------
# Fonction de log
# ------------------------------------------------------------
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# ------------------------------------------------------------
# Options CLI
# ------------------------------------------------------------
CHECK_MODE=0
DRY_RUN=0
TAGS=""
LIST_HOSTS=0
LIST_TAGS=0

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options :"
    echo "  --check              Exécute Ansible en mode check"
    echo "  --tags tag1,tag2     Exécute uniquement certains tags"
    echo "  --dry-run            Affiche la commande sans l'exécuter"
    echo "  --target <hôte>      Cible spécifique (localhost, vagrantvm)"
    echo "  --list-hosts         Affiche les hôtes ciblés"
    echo "  --list-tags          Affiche les tags disponibles"
    echo "  -h, --help           Affiche cette aide"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check) CHECK_MODE=1; shift ;;
        --tags) [[ $# -lt 2 ]] && { echo "Erreur: --tags nécessite un argument"; exit 1; }
                TAGS="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --target) [[ $# -lt 2 ]] && { echo "Erreur: --target nécessite un argument"; exit 1; }
                  TARGET="$2"; shift 2 ;;
        --list-hosts) LIST_HOSTS=1; shift ;;
        --list-tags) LIST_TAGS=1; shift ;;
        -h|--help) usage ;;
        *) echo "Option inconnue : $1"; usage ;;
    esac
done

log "===== Début du provisioning de la workstation ====="
log "Options : check=$CHECK_MODE, tags='$TAGS', dry-run=$DRY_RUN, target=$TARGET"

# ------------------------------------------------------------
# Vérification du fichier Vault
# ------------------------------------------------------------
if [[ ! -f "$VAULT_PASS_FILE" ]]; then
    log "ERREUR : fichier Vault manquant : $VAULT_PASS_FILE"
    exit 1
fi

# ------------------------------------------------------------
# Vérification d'Ansible
# ------------------------------------------------------------
if ! command -v ansible-playbook >/dev/null 2>&1; then
    log "Ansible non installé. Installation via dnf..."
    sudo dnf install -y ansible 2>&1 | tee -a "$LOGFILE"
else
    log "Ansible déjà installé."
fi

# ------------------------------------------------------------
# Auto-détection Vagrant
# ------------------------------------------------------------
TEMP_INVENTORY="$(mktemp /tmp/vagrant_inventory_XXXX.yml)"

if [[ "$TARGET" == "vagrantvm" ]]; then
    if [[ ! -d "$VAGRANT_DIR/.vagrant" ]]; then
        log "ERREUR : Aucun environnement Vagrant trouvé dans $VAGRANT_DIR"
        exit 1
    fi

    log "Détection automatique de la VM Vagrant..."

    SSH_CONFIG=$(cd "$VAGRANT_DIR" && vagrant ssh-config)

    HOST=$(echo "$SSH_CONFIG" | awk '/HostName/ {print $2}')
    USER=$(echo "$SSH_CONFIG" | awk '/User / {print $2}')
    PORT=$(echo "$SSH_CONFIG" | awk '/Port/ {print $2}')
    KEY=$(echo "$SSH_CONFIG" | awk '/IdentityFile/ {print $2}')

    log "Vagrant détecté :"
    log "  Host = $HOST"
    log "  User = $USER"
    log "  Port = $PORT"
    log "  Key  = $KEY"

    cat > "$TEMP_INVENTORY" <<EOF
all:
  hosts:
    vagrantvm:
      ansible_host: "$HOST"
      ansible_user: "$USER"
      ansible_port: $PORT
      ansible_ssh_private_key_file: "$KEY"
      ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
EOF

    INVENTORY_FILE="$TEMP_INVENTORY"
    EXTRA_VARS="vagrant_ip=$HOST"
else
    INVENTORY_FILE="$PROJECT_ROOT/inventory/hosts"
    EXTRA_VARS=""
fi

# ------------------------------------------------------------
# Mode dry-run
# ------------------------------------------------------------
if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY-RUN] Aucun changement ne sera effectué."
    exit 0
fi

# ------------------------------------------------------------
# Commandes spéciales
# ------------------------------------------------------------
if [[ "$LIST_HOSTS" -eq 1 ]]; then
    cd "$PROJECT_ROOT"
    ansible-playbook site.yml -i "$INVENTORY_FILE" -l "$TARGET" --list-hosts --vault-password-file "$VAULT_PASS_FILE"
    exit 0
fi

if [[ "$LIST_TAGS" -eq 1 ]]; then
    cd "$PROJECT_ROOT"
    ansible-playbook site.yml -i "$INVENTORY_FILE" -l "$TARGET" --list-tags --vault-password-file "$VAULT_PASS_FILE"
    exit 0
fi

# ------------------------------------------------------------
# IMPORTANT : se placer dans le dossier du projet
# ------------------------------------------------------------
cd "$PROJECT_ROOT"

# ------------------------------------------------------------
# Construction de la commande Ansible
# ------------------------------------------------------------
ANSIBLE_CMD=(
    ansible-playbook site.yml
    -i "$INVENTORY_FILE"
    -l "$TARGET"
    --vault-password-file "$VAULT_PASS_FILE"
)

if [[ "$TARGET" == "localhost" ]]; then
    ANSIBLE_CMD+=(--ask-become-pass)
fi

[[ "$CHECK_MODE" -eq 1 ]] && ANSIBLE_CMD+=(--check)
[[ -n "$TAGS" ]] && ANSIBLE_CMD+=(--tags "$TAGS")
[[ -n "$EXTRA_VARS" ]] && ANSIBLE_CMD+=(--extra-vars "$EXTRA_VARS")

log "Commande exécutée : ${ANSIBLE_CMD[*]}"

# ------------------------------------------------------------
# Exécution du playbook
# ------------------------------------------------------------
"${ANSIBLE_CMD[@]}" \
  > >(tee -a "$LOGFILE") \
  2> >(tee -a "$LOGFILE")

log "===== Provisioning terminé ====="
log "Log complet disponible dans : $LOGFILE"

#!/usr/bin/env bash

set -e

# ---------------------------------------------------------
# Script : vagrant-clean.sh
# Objectif : Arrêter, détruire et nettoyer une VM Vagrant
# ---------------------------------------------------------

FORCE=0

# --- Analyse des options ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=1 ;;
        *) echo "Option inconnue : $1"; exit 1 ;;
    esac
    shift
done

# --- Vérification présence d'un Vagrantfile ---
if [[ ! -f "Vagrantfile" ]]; then
    echo "Erreur : aucun Vagrantfile trouvé dans ce dossier."
    exit 1
fi

# --- Vérification de l'état de la VM ---
VM_STATE=$(vagrant status --machine-readable | grep ",state," | cut -d',' -f4)

echo "Etat actuel de la VM : $VM_STATE"

# --- Arrêt de la VM si nécessaire ---
if [[ "$VM_STATE" == "running" ]]; then
    echo "Arret de la VM..."
    vagrant halt
else
    echo "La VM n'est pas en cours d'exécution."
fi

# --- Confirmation si pas en mode force ---
if [[ $FORCE -eq 0 ]]; then
    read -p "Voulez-vous vraiment détruire la VM et supprimer .vagrant ? (o/N) " confirm
    if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
        echo "Operation annulée."
        exit 0
    fi
fi

# --- Destruction de la VM ---
echo "Destruction de la VM..."
vagrant destroy -f

# --- Suppression du dossier .vagrant ---
if [[ -d ".vagrant" ]]; then
    echo "Suppression du dossier .vagrant..."
    rm -rf .vagrant
else
    echo "Aucun dossier .vagrant à supprimer."
fi

echo "Nettoyage terminé."


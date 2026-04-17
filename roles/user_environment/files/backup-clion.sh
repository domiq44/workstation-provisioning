#!/usr/bin/env bash

cd ~/CLionProjects

# Construire la liste des chemins à sauvegarder
FILES=""

for d in */ ; do
    if [ -d "$d/.git" ]; then
        # Sauvegarder le dossier .git
        FILES="$FILES $d.git"

        # Sauvegarder les fichiers suivis
        FILES="$FILES $(cd "$d" && git ls-files | sed "s|^|$d|")"
    fi
done

# Sauvegarde Borg
borg create \
    --progress \
    --stats \
    --compression lz4 \
    ~/borg/clion::"$(date +%Y-%m-%d_%H-%M)" \
    $FILES

# Rotation
borg prune ~/borg/clion \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=6 \
    --stats


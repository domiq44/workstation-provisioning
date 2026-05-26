#!/usr/bin/env bash

ts=$(date +"%Y-%m-%d_%H-%M-%S")
logfile="vagrant_up_${ts}.log"

start_ts=$(date +%s)

# En-tête du log
{
  echo "COMMAND: vagrant up"
  echo "DATE: $(date)"
  echo "----------------------------------------"
} > "$logfile"

# Exécution avec couleurs + affichage temps réel + log
# On force Vagrant à garder les couleurs
VAGRANT_FORCE_COLOR=1 vagrant up 2>&1 \
  | tee >(sed -r "s/\x1B\[[0-9;]*[mK]//g" >> "$logfile")
status=${PIPESTATUS[0]}

end_ts=$(date +%s)
duration=$(( end_ts - start_ts ))

printf -v duration_hms "%02d:%02d:%02d" \
  $((duration/3600)) $(( (duration%3600)/60 )) $((duration%60))

{
  echo "----------------------------------------"
  echo "DURATION: ${duration_hms}"
} >> "$logfile"

if [ $status -eq 0 ]; then
    final="vagrant_up_${ts}_ok.log"
    mv "$logfile" "$final"
    echo "✔ vagrant up OK — durée : ${duration_hms} — log : $final"
else
    final="vagrant_up_${ts}_ko.log"
    mv "$logfile" "$final"
    echo "✘ vagrant up KO — durée : ${duration_hms} — log : $final"
fi

exit $status


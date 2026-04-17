get_ip() {
    hostname -I | awk '{print $1}'
}

# Fonction pour afficher le code retour (sans retour à la ligne)
show_rc() {
    local rc=$?
    printf "\e[36m[$rc]\e[0m"
}

# PROMPT_COMMAND reconstruit PS1 dynamiquement
PROMPT_COMMAND='show_rc; PS1="[\[\e[34m\]\u\[\e[0m\]@\[\e[32m\]\h\[\e[0m\]](\[\e[33m\]$(get_ip)\[\e[0m\]):\[\e[36m\]${PWD}\[\e[0m\]\n\$ "'



# --- Git ---
alias gs='git status'

# --- Docker ---
alias db='docker build -t $USER/$(basename $(pwd)) .'
alias dr='docker run --rm -ti $USER/$(basename $(pwd)) $*'
alias drmi='docker rmi $USER/$(basename $(pwd))'

# --- ls ---
alias ll='ls -lF'
alias la='ls -A'
alias l='ls -CF'
alias lf='ls -F'

# --- Autres ---
alias ff='fastfetch'
alias yazi='flatpak run io.github.sxyazi.yazi'


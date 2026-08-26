eval "$(~/.local/bin/mise activate zsh)"
eval "$(starship init zsh)"
eval "$(sheldon source)"
eval "$(zoxide init zsh)"

autoload -U compinit
compinit

source "$HOME/.ghcup/env"
source ~/.cargo/env

export EDITOR="hx"
export VISUAL="hx"

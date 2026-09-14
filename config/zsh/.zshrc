typeset -U path
path=("$HOME/.local/bin" /opt/homebrew/bin /opt/homebrew/sbin $path)
export PATH

eval "$(~/.local/bin/mise activate zsh)"
eval "$(starship init zsh)"
eval "$(sheldon source)"
eval "$(zoxide init zsh)"

autoload -U compinit
compinit

[[ ! -r "$HOME/.ghcup/env" ]] || source "$HOME/.ghcup/env"
[[ ! -r "$HOME/.cargo/env" ]] || source "$HOME/.cargo/env"

export EDITOR="hx"
export VISUAL="hx"


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" > /dev/null 2> /dev/null
# END opam configuration

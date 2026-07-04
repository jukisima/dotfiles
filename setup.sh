#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BREWFILE="${SCRIPT_DIR}/Brewfile"
readonly MISE_CONFIG_FILE="${SCRIPT_DIR}/mise.toml"
readonly BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"

log() {
	printf '==> %s\n' "$*"
}

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

ensure_macos() {
	[[ "$(uname -s)" == "Darwin" ]] || die "this bootstrap currently supports macOS only."
}

install_homebrew() {
	if command -v brew >/dev/null 2>&1; then
		return
	fi

	command -v curl >/dev/null 2>&1 || die "curl is required to install homebrew."

	log "installing homebrew"
	NONINTERACTIVE=1 /bin/bash -c \
		"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

source_homebrew() {
	[[ -x /opt/homebrew/bin/brew ]] || die "homebrew was installed, but /opt/homebrew/bin/brew is not available."
	eval "$(/opt/homebrew/bin/brew shellenv)"
}

install_brew_packages() {
	log "installing homebrew packages"
	if brew bundle --file "${BREWFILE}"; then
		return
	fi

	printf 'warning: brew bundle reported one or more failed dependencies; continuing setup.\n' >&2
	printf 'warning: rerun `brew bundle --file %s` later to retry skipped installs.\n' "${BREWFILE}" >&2
}

backup_path() {
	local target="$1"
	local backup="${target}.backup-${BACKUP_SUFFIX}"

	log "backing up ${target} to ${backup}"
	mv "$target" "$backup"
}

resolve_symlink_target() {
	local link_path="$1"
	local link_target

	link_target="$(readlink "${link_path}")"
	if [[ "${link_target}" == /* ]]; then
		printf '%s\n' "${link_target}"
	else
		(
			cd -- "$(dirname "${link_path}")"
			cd -- "$(dirname "${link_target}")"
			printf '%s/%s\n' "$(pwd -P)" "$(basename "${link_target}")"
		)
	fi
}

backup_dotfile_if_needed() {
	local source="$1"
	local target="$2"

	if [[ -L "${target}" ]]; then
		[[ "$(resolve_symlink_target "${target}")" == "${source}" ]] && return
	fi

	if [[ -e "${target}" || -L "${target}" ]]; then
		backup_path "${target}"
	fi
}

backup_existing_dotfiles() {
	log "backing up conflicting dotfiles before applying symlinks"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/git/.gitconfig" "${HOME}/.gitconfig"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/zsh/.zprofile" "${HOME}/.zprofile"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/zsh/.zshrc" "${HOME}/.zshrc"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/mise/config.toml" "${HOME}/.config/mise/config.toml"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/starship.toml" "${HOME}/.config/starship.toml"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/warp/settings.toml" "${HOME}/.warp/settings.toml"
}

trust_mise_config() {
	log "trusting ${MISE_CONFIG_FILE}"
	mise trust "${MISE_CONFIG_FILE}"
}

install_mise_tools() {
	log "installing mise-managed tools"
	mise install
}

apply_dotfiles() {
	log "applying repo-managed dotfiles"
	MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
}

start_syncthing() {
	log "starting syncthing with brew services"
	brew services start syncthing >/dev/null
}

main() {
	ensure_macos
	cd "${SCRIPT_DIR}"
	install_homebrew
	source_homebrew
	install_brew_packages
	trust_mise_config
	backup_existing_dotfiles
	apply_dotfiles
	install_mise_tools
	start_syncthing

	log "done"
	log "open a new shell to pick up homebrew and mise shell integration."
}

main "$@"

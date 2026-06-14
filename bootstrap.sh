#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly FLAKE_ATTR="default"
readonly NIX_CONF_DIR="${HOME}/.config/nix"
readonly NIX_CONF_FILE="${NIX_CONF_DIR}/nix.conf"
readonly NIX_FEATURES_LINE="experimental-features = nix-command flakes"

log() {
	printf '==> %s\n' "$*"
}

die() {
	printf 'error: %s\n' "$*" >&2
	exit 1
}

assert_supported_machine() {
	local os arch
	os="$(uname -s)"
	arch="$(uname -m)"

	[[ "$os" == "Darwin" ]] || die "This bootstrap currently supports macOS only."
	[[ "$arch" == "arm64" ]] || die "This flake is currently pinned for arm64 Macs."
	[[ -n "${USER:-}" ]] || die "USER is not set."
	[[ -n "${HOME:-}" ]] || die "HOME is not set."
}

ensure_repo_root() {
	[[ -f "${SCRIPT_DIR}/flake.nix" ]] || die "flake.nix was not found next to bootstrap.sh"
	[[ -f "${SCRIPT_DIR}/home.nix" ]] || die "home.nix was not found next to bootstrap.sh"
}

install_nix() {
	if command -v nix >/dev/null 2>&1; then
		return
	fi

	command -v curl >/dev/null 2>&1 || die "curl is required to install Nix."

	log "Installing Nix with the official macOS installer"
	curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
}

source_nix() {
	if command -v nix >/dev/null 2>&1; then
		return
	fi

	if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
		# shellcheck disable=SC1091
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
	elif [[ -f "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
		# shellcheck disable=SC1090
		. "${HOME}/.nix-profile/etc/profile.d/nix.sh"
	fi

	command -v nix >/dev/null 2>&1 || die "Nix is still not available in PATH. Open a new shell and rerun bootstrap.sh."
}

ensure_flakes_enabled() {
	mkdir -p "${NIX_CONF_DIR}"

	if [[ -f "${NIX_CONF_FILE}" ]] && grep -Eq '^[[:space:]]*experimental-features[[:space:]]*=.*nix-command.*flakes|^[[:space:]]*experimental-features[[:space:]]*=.*flakes.*nix-command' "${NIX_CONF_FILE}"; then
		return
	fi

	log "Enabling nix-command and flakes in ${NIX_CONF_FILE}"
	{
		printf '\n'
		printf '%s\n' "${NIX_FEATURES_LINE}"
	} >>"${NIX_CONF_FILE}"
}

apply_home_manager() {
	log "Applying Home Manager from ${SCRIPT_DIR}"
	nix --extra-experimental-features 'nix-command flakes' \
		run github:nix-community/home-manager/release-26.05 \
		-- switch -b backup --impure --flake "path:${SCRIPT_DIR}#${FLAKE_ATTR}"
}

main() {
	assert_supported_machine
	ensure_repo_root
	install_nix
	source_nix
	ensure_flakes_enabled
	apply_home_manager

	log "Done"
	log "Open a new shell to pick up login-time changes if needed."
}

main "$@"

#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly BREWFILE="${SCRIPT_DIR}/Brewfile"
readonly MISE_CONFIG_FILE="${SCRIPT_DIR}/mise.toml"
readonly USER_FONT_DIR="${HOME}/Library/Fonts"
readonly BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"
readonly ALEGREYA_ARCHIVE_URL="https://github.com/huertatipografica/Alegreya/archive/refs/tags/v2.008.tar.gz"
readonly ALCARIN_TENGWAR_ARCHIVE_URL="https://github.com/Tosche/Alcarin-Tengwar/archive/a4530d430ea01871b0b0a54d1de218d2ffde0ea5.tar.gz"
readonly LIBERTINUS_ARCHIVE_URL="https://github.com/alerque/libertinus/releases/download/v7.051/Libertinus-7.051.tar.zst"

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
	[[ "$arch" == "arm64" ]] || die "This bootstrap is currently pinned for arm64 Macs."
	[[ -n "${USER:-}" ]] || die "USER is not set."
	[[ -n "${HOME:-}" ]] || die "HOME is not set."
}

ensure_repo_root() {
	[[ -f "${BREWFILE}" ]] || die "Brewfile was not found next to setup.sh"
	[[ -f "${MISE_CONFIG_FILE}" ]] || die "mise.toml was not found next to setup.sh"
	[[ -f "${SCRIPT_DIR}/config/vscode/settings.json" ]] || die "VS Code settings were not found in config/vscode"
	[[ -f "${SCRIPT_DIR}/config/warp/settings.toml" ]] || die "Warp settings were not found in config/warp"
}

install_homebrew() {
	if command -v brew >/dev/null 2>&1; then
		return
	fi

	command -v curl >/dev/null 2>&1 || die "curl is required to install Homebrew."

	log "Installing Homebrew"
	NONINTERACTIVE=1 /bin/bash -c \
		"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

source_homebrew() {
	if [[ -x /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi

	command -v brew >/dev/null 2>&1 || die "Homebrew is still not available in PATH. Open a new shell and rerun setup.sh."
}

ensure_homebrew_writable() {
	local brew_prefix
	local -a required_paths unwritable_paths

	brew_prefix="$(brew --prefix)"
	required_paths=(
		"${HOME}/Library/Caches/Homebrew"
		"${HOME}/Library/Logs/Homebrew"
		"${brew_prefix}"
		"${brew_prefix}/Cellar"
		"${brew_prefix}/Frameworks"
		"${brew_prefix}/bin"
		"${brew_prefix}/etc"
		"${brew_prefix}/etc/bash_completion.d"
		"${brew_prefix}/include"
		"${brew_prefix}/lib"
		"${brew_prefix}/lib/pkgconfig"
		"${brew_prefix}/opt"
		"${brew_prefix}/sbin"
		"${brew_prefix}/share"
		"${brew_prefix}/share/doc"
		"${brew_prefix}/share/man"
		"${brew_prefix}/share/man/man1"
		"${brew_prefix}/share/man/man3"
		"${brew_prefix}/share/man/man5"
		"${brew_prefix}/share/man/man7"
		"${brew_prefix}/share/zsh"
		"${brew_prefix}/share/zsh/site-functions"
		"${brew_prefix}/var/homebrew/linked"
		"${brew_prefix}/var/homebrew/locks"
		"${brew_prefix}/var/log"
	)

	for path in "${required_paths[@]}"; do
		if [[ -e "${path}" ]]; then
			[[ -w "${path}" ]] || unwritable_paths+=("${path}")
		else
			local parent_dir
			parent_dir="$(dirname "${path}")"
			[[ -w "${parent_dir}" ]] || unwritable_paths+=("${path}")
		fi
	done

	((${#unwritable_paths[@]} == 0)) && return

	printf 'error: Homebrew is installed but some required paths are not writable by %s.\n' "${USER}" >&2
	printf 'Fix it with:\n' >&2
	printf '  sudo chown -R %s %s\n' "${USER}" "${unwritable_paths[*]}" >&2
	printf '  chmod u+w %s\n' "${unwritable_paths[*]}" >&2
	exit 1
}

install_brew_packages() {
	log "Installing Homebrew packages"
	if brew bundle --file "${BREWFILE}"; then
		return
	fi

	printf 'warning: brew bundle reported one or more failed dependencies; continuing setup.\n' >&2
	printf 'warning: rerun `brew bundle --file %s` later to retry skipped installs.\n' "${BREWFILE}" >&2
}

backup_path() {
	local target="$1"
	local backup="${target}.backup-${BACKUP_SUFFIX}"

	log "Backing up ${target} to ${backup}"
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
	log "Backing up conflicting dotfiles before applying symlinks"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/git/.gitconfig" "${HOME}/.gitconfig"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/zsh/.zprofile" "${HOME}/.zprofile"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/zsh/.zshrc" "${HOME}/.zshrc"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/starship.toml" "${HOME}/.config/starship.toml"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/vscode/settings.json" "${HOME}/Library/Application Support/Code/User/settings.json"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/warp/settings.toml" "${HOME}/.warp/settings.toml"
	backup_dotfile_if_needed "${SCRIPT_DIR}/config/dotfiles/example.conf" "${HOME}/.config/dotfiles/example.conf"
}

trust_mise_config() {
	log "Trusting ${MISE_CONFIG_FILE}"
	mise trust "${MISE_CONFIG_FILE}"
}

install_mise_tools() {
	log "Installing mise-managed tools"
	mise install
}

apply_dotfiles() {
	log "Applying repo-managed dotfiles"
	MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
}

extract_archive() {
	local archive_path="$1"
	local target_dir="$2"

	case "${archive_path}" in
	*.tar.gz)
		tar -xzf "${archive_path}" -C "${target_dir}"
		;;
	*.tar.zst)
		tar --use-compress-program=unzstd -xf "${archive_path}" -C "${target_dir}"
		;;
	*)
		die "Unsupported archive format: ${archive_path}"
		;;
	esac
}

install_fonts_from_archive() {
	local family="$1"
	local archive_url="$2"
	local name_pattern="$3"
	local archive_name="$4"
	local tmpdir installed=0

	log "Installing ${family} fonts"
	mkdir -p "${USER_FONT_DIR}"
	tmpdir="$(mktemp -d)"
	curl -fsSL "${archive_url}" -o "${tmpdir}/${archive_name}"
	extract_archive "${tmpdir}/${archive_name}" "${tmpdir}"

	while IFS= read -r -d '' font_file; do
		install -m 644 "${font_file}" "${USER_FONT_DIR}/$(basename "${font_file}")"
		installed=1
	done < <(find "${tmpdir}" -type f \( -name "${name_pattern}*.ttf" -o -name "${name_pattern}*.otf" \) -print0)

	rm -rf "${tmpdir}"

	((installed == 1)) || die "No ${family} font files matching ${name_pattern}* were found in ${archive_url}"
}

install_manual_fonts() {
	install_fonts_from_archive "Alegreya" "${ALEGREYA_ARCHIVE_URL}" "Alegreya" "alegreya.tar.gz"
	install_fonts_from_archive "Alcarin Tengwar" "${ALCARIN_TENGWAR_ARCHIVE_URL}" "AlcarinTengwar" "alcarin-tengwar.tar.gz"
	install_fonts_from_archive "Libertinus" "${LIBERTINUS_ARCHIVE_URL}" "Libertinus" "libertinus.tar.zst"
}

start_syncthing() {
	log "Starting Syncthing with brew services"
	brew services start syncthing >/dev/null
}

main() {
	assert_supported_machine
	ensure_repo_root
	cd "${SCRIPT_DIR}"
	install_homebrew
	source_homebrew
	ensure_homebrew_writable
	install_brew_packages
	trust_mise_config
	install_mise_tools
	backup_existing_dotfiles
	apply_dotfiles
	install_manual_fonts
	start_syncthing

	log "Done"
	log "Open a new shell to pick up Homebrew and mise shell integration."
}

main "$@"

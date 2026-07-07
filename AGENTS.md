# AGENTS

This repository is a standalone macOS dotfiles setup for one Apple Silicon
machine. Use this file as the single source of truth for agent-facing guidance.

## Scope

- Prefer small, local edits.
- Keep the setup standalone.
- Preserve the current shape: `setup.sh` + `Brewfile` + `mise.toml` + `config/`.
- Prefer extending existing files over introducing new structure.

## Current assumptions

- Target OS: macOS
- Target architecture: `aarch64-darwin` / Apple Silicon
- Target user/home: resolved from `USER` and `HOME` at runtime
- Homebrew prefix: `/opt/homebrew`

## Repo map

- `setup.sh`: bootstrap and re-apply entrypoint
- `Brewfile`: Homebrew formulae, casks, and taps
- `mise.toml`: `mise dotfiles` mapping
- `config/mise/config.toml`: global `mise` tools
- `config/codex/config.toml`: Codex config
- `config/zsh/.zprofile`: PATH setup
- `config/zsh/.zshrc`: shared shell config
- `config/starship.toml`: prompt config
- `config/vscode/settings.json`: VS Code user settings
- `config/warp/settings.toml`: Warp settings

## Preferred workflow

- For first-time setup on a new machine, use:

  ```bash
  ./setup.sh
  ```

- `setup.sh` currently:

  ```bash
  brew trust --tap gcenx/wine
  brew uninstall --cask wine-stable  # if installed
  brew bundle --file "${BREWFILE}"
  MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
  mise install
  brew services start syncthing
  ```

- For normal re-apply, prefer:

  ```bash
  brew trust --tap gcenx/wine
  brew uninstall --cask wine-stable  # if installed
  brew bundle
  MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
  mise install
  brew services start syncthing
  ```

## Editing guidance

- Keep Homebrew package additions in `Brewfile`.
- Keep version-managed tool changes in `config/mise/config.toml` under `[tools]`.
- Keep dotfile ownership in `mise.toml` under `[dotfiles]`.
- Keep shell configuration in `config/zsh/.zprofile` and `config/zsh/.zshrc`.
- Keep editor configuration in repo-managed files where practical.
- VS Code user settings live in `config/vscode/settings.json`.
- Warp settings live in `config/warp/settings.toml`.
- Update this file when bootstrap or everyday usage changes.

## Current managed software

- Homebrew formulae for CLI tools like `helix`, `mise`, `ripgrep`, `shfmt`,
  `syncthing`, `typst`, `winetricks`, `zoxide`, and zsh plugins
- Homebrew tap trust for `gcenx/wine`
- Homebrew casks for apps including `anki`, `blender`, `calibre`, `codex-app`,
  `discord`, `element`, `firefox`, `game-porting-toolkit`, `google-chrome`,
  `kobo`, `signal`, `spotify`, `steam`, `visual-studio-code`, `warp`, and
  `zed`
- Homebrew casks for fonts including `Alegreya`, `JetBrains Mono Nerd Font`,
  `Libertinus Math`, `LXGW WenKai TC`, `Noto Kufi Arabic`,
  `Noto Naskh Arabic`, `Noto Sans`, `Noto Sans TC`, `Noto Serif`,
  `Noto Serif Hentaigana`, `Noto Serif TC`, and `Shippori Mincho`

## Notes

- `mise` cannot install itself on an empty machine, so it is installed with
  Homebrew first.
- `mise dotfiles` is experimental here, so use `MISE_EXPERIMENTAL=1`.
- `config/mise/config.toml` is symlinked into `~/.config/mise/config.toml`.
- `ruby` via `mise` needs `libyaml` and `pkgconf` for the `psych` extension.
- Because `gcenx/wine` provides a cask in this repo, Homebrew tap trust is part
  of normal setup.
- `gcenx/wine/game-porting-toolkit` conflicts with `wine-stable`, so remove
  `wine-stable` before installing or re-applying on machines that already have
  it.
- If `/Applications/Signal.app` already exists outside Homebrew management,
  move or remove it before running `brew bundle`, otherwise Homebrew may fail
  while trying to adopt the app bundle.

## Verification

After changing setup behavior, run:

```bash
shfmt -w setup.sh
bash -n setup.sh
```

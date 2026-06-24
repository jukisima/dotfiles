# AGENTS

This repository is a small standalone dotfiles setup for one macOS machine
profile.

## Scope

- Prefer small, local edits.
- Keep the setup standalone.
- Preserve the current shape: `setup.sh` + `Brewfile` + `mise.toml` + `config/`.

## Current assumptions

- Target OS: macOS
- Target architecture: `aarch64-darwin` / Apple Silicon
- Target user/home: resolved from `USER` and `HOME` at runtime

## Preferred workflow

- For first-time setup on a new machine, use:

  ```bash
  ./setup.sh
  ```

- For normal re-apply, prefer:

  ```bash
  brew bundle
  mise install
  MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
  brew services start syncthing
  ```

## Editing guidance

- Keep Homebrew package additions in `Brewfile`.
- Keep version-managed tool changes in `mise.toml` under `[tools]`.
- Keep dotfile ownership in `mise.toml` under `[dotfiles]`.
- Keep shell configuration in `config/zsh/.zprofile` and `config/zsh/.zshrc`.
- Keep editor configuration in repo-managed files where practical. VS Code user
  settings live in `config/vscode/settings.json`.
- Keep Warp settings in `config/warp/settings.toml`.
- Update `README.md` when bootstrap or everyday usage changes.

## Verification

After changing setup behavior, run:

```bash
shfmt -w setup.sh
bash -n setup.sh
```

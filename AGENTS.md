# AGENTS

This repository is a small `home-manager`-based dotfiles setup for one machine profile.

## Scope

- Prefer small, local edits.
- Keep the setup standalone. Do not introduce `nix-darwin` unless explicitly requested.
- Preserve the current shape: `flake.nix` + `home.nix` + `bootstrap.sh`.

## Current assumptions

- Target OS: macOS
- Target architecture: `aarch64-darwin` / Apple Silicon
- Target user/home: resolved from `USER` and `HOME` at evaluation time

`home.nix` receives `homeDirectory` as an argument from [flake.nix](./flake.nix), and derives `username` from it. Because the flake reads `HOME`, direct flake commands must use `--impure`.

## Preferred workflow

- For first-time setup on a new machine, use:

  ```bash
  ./bootstrap.sh
  ```

- For normal re-apply, use:

  ```bash
  home-manager switch --impure --flake path:.#default
  ```

- When referencing the local flake, prefer `path:.#default` or `path:/abs/path#default`. This repo may contain untracked files, and plain `.#default` can fail because Nix only sees Git-tracked files in that mode.
- Because this flake derives `homeDirectory` from environment variables, direct flake commands also need `--impure`.

## Editing guidance

- Keep package additions in `home.nix` under `home.packages`.
- Keep shell configuration in Home Manager options when possible.
- Keep editor configuration in repo-managed files where practical. VS Code user settings live in `config/vscode/settings.json` and are wired through `programs.vscode`.
- Keep Warp settings in `config/warp/settings.toml` and link them with `home.file` because Warp reads `~/.warp/settings.toml`.
- Prefer Home Manager built-in modules/options over external plugin managers or ad hoc shell sourcing.
- If a package is unfree, allow only the specific package name in `flake.nix`; do not switch to broad `allowUnfree = true`.
- Update `README.md` when bootstrap or everyday usage changes.

## Verification

After changing Nix files or bootstrap behavior, run:

```bash
shfmt -w bootstrap.sh
bash -n bootstrap.sh
nix --extra-experimental-features 'nix-command flakes' eval --impure --raw 'path:.#homeConfigurations.default.activationPackage.drvPath'
```

If the task changes the flake target path, adjust the second command accordingly.

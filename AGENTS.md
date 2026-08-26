# AGENTS

This repository is a standalone macOS dotfiles setup for one Apple Silicon
machine. Use this file as the single source of truth for agent-facing guidance.

## Scope

- Prefer small, local edits.
- Keep the setup standalone.
- Preserve the current shape: `mise.toml` + `config/`.
- Prefer extending existing files over introducing new structure.

## Current assumptions

- Target OS: macOS
- Target architecture: `aarch64-darwin` / Apple Silicon
- Target user/home: resolved from `USER` and `HOME` at runtime
- Homebrew-compatible package prefix: `/opt/homebrew`

## Repo map

- `mise.toml`: bootstrap packages, tools, and dotfile mapping
- `config/mise/config.toml`: global `mise` tools
- `config/codex/config.toml`: Codex config
- `config/zsh/.zprofile`: PATH setup
- `config/zsh/.zshrc`: shared shell config
- `config/starship.toml`: prompt config
- `config/vscode/settings.json`: VS Code user settings
- `config/warp/settings.toml`: Warp settings

## Preferred workflow

- For first-time setup on a new machine, install `mise`, then use:

  ```bash
  mise trust
  mise bootstrap --yes
  ```

- `mise bootstrap` currently:

  ```bash
  mise bootstrap packages apply
  mise bootstrap dotfiles apply
  mise install
  ```

- For normal re-apply, prefer:

  ```bash
  mise bootstrap --yes
  ```

## Editing guidance

- Keep host package additions in `mise.toml` under `[bootstrap.packages]`.
- Keep version-managed tool changes in `config/mise/config.toml` under `[tools]`.
- Keep dotfile ownership in `mise.toml` under `[dotfiles]`.
- Keep shell configuration in `config/zsh/.zprofile` and `config/zsh/.zshrc`.
- Keep editor configuration in repo-managed files where practical.
- VS Code user settings live in `config/vscode/settings.json`.
- Warp settings live in `config/warp/settings.toml`.
- Update this file when bootstrap or everyday usage changes.

## Current managed software

- Bootstrap formulae for CLI tools like `helix`, `mise`, `ripgrep`, `shfmt`,
  `typst`, `winetricks`, `zoxide`, and zsh plugins
- Bootstrap casks for apps including `anki`, `brave-browser`, `calibre`,
  `codex`, `discord`, `element`, `ghostty`, `google-chrome`, `iina`, `kobo`,
  `obs`, `session`, `spotify`, `steam`, `visual-studio-code`, and `zotero`
- Bootstrap casks for fonts including `Alegreya`, GNU Unifont,
  `JetBrains Mono Nerd Font`, `Libertinus Math`, `LXGW WenKai TC`,
  `Nanum Myeongjo`, `Noto Kufi Arabic`, `Noto Naskh Arabic`, `Noto Sans`,
  `Noto Sans Armenian`, `Noto Sans TC`, `Noto Serif`,
  `Noto Serif Hentaigana`, `Noto Serif TC`, `Noto Sans Psalter Pahlavi`, and
  `Shippori Mincho`

## Notes

- `mise` cannot bootstrap itself on an empty machine, so install it first.
- Bootstrap requires `mise` 2026.8.14 or later so existing Homebrew-owned
  casks satisfy matching package entries without being replaced.
- The built-in `brew` and `brew-cask` package managers install directly into
  `/opt/homebrew`; the Homebrew CLI is not required.
- `bootstrap.brew.adopt = true` lets mise adopt identical existing app bundles
  when migrating casks that are not currently package-manager-owned.
- Blender is not bootstrap-managed because its cask uses the unsupported
  `set_permissions` preflight step.
- If an existing file conflicts with a managed dotfile, inspect or move it
  before retrying; use `--force-dotfiles` only when overwriting it is intended.
- `config/mise/config.toml` is symlinked into `~/.config/mise/config.toml`.
- `ruby` via `mise` needs `libyaml` and `pkgconf` for the `psych` extension.

## Verification

After changing bootstrap behavior, run:

```bash
mise bootstrap --dry-run --yes
mise bootstrap packages status --missing
```

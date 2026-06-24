# dotfiles

この構成は macOS 向けの standalone な dotfiles です。Nix / Home Manager
ではなく、Homebrew と `mise` を使ってツール導入と設定反映を行います。

## Files

- `setup.sh`: 初期セットアップと再反映
- `Brewfile`: Homebrew で入れる formula / cask
- `mise.toml`: `mise` で入れる version-managed tools と dotfiles 定義
- `config/zsh/.zprofile`: Homebrew と `~/.local/bin` の PATH
- `config/zsh/.zshrc`: zsh の共通設定
- `config/starship.toml`: starship 設定
- `config/vscode/settings.json`: VS Code の user settings
- `config/warp/settings.toml`: Warp の settings
- `config/dotfiles/example.conf`: repo に置いたまま配るサンプル dotfile

## Bootstrap

新しいマシンでは、この repo を clone したあとにまず次を実行します。

```bash
./setup.sh
```

このスクリプトは次をやります。

- Homebrew が未導入なら公式 installer で入れる
- `Brewfile` の formula / cask を入れる
- `mise.toml` を trust して `mise install` を実行する
- `mise dotfiles apply` で repo-managed dotfiles を symlink する
- dotfiles 競合時は `*.backup-YYYYMMDDHHMMSS` へ退避する
- `brew services start syncthing` で Syncthing を自動起動する

## Re-apply

2 回目以降も `./setup.sh` で再反映できます。

より短い日常運用なら次でも十分です。

```bash
brew bundle
mise install
MISE_EXPERIMENTAL=1 mise dotfiles apply --yes
brew services start syncthing
```

## What this setup does

- Homebrew で `fdupes`、`helix`、`ripgrep`、`rsync`、`shfmt`、`starship`、
  `syncthing`、`typst`、`zoxide` と zsh plugin 用 formula を入れる
- Homebrew で `mise` を入れる
- Homebrew cask で `codex-app`、`google-chrome`、`visual-studio-code`、`warp`、`zed` を入れる
- Homebrew cask で `Alegreya`、`JetBrains Mono Nerd Font`、`Libertinus Math`、`LXGW WenKai TC`、`Shippori Mincho` を入れる
- `mise` で `deno`、`java`、`node`、`mystmd` を入れる
- repo の `config/` 配下を `mise dotfiles` でホームディレクトリへ symlink する
- `~/.gitconfig` で `init.defaultBranch = main` を設定する
- zsh では `mise activate`、`zoxide`、`starship`、completion、
  autosuggestion、syntax highlighting、history substring search を有効化する
- `EDITOR` と `VISUAL` を `hx` に設定する

## First edits

最初は `Brewfile`、`mise.toml`、`config/` を触れば十分です。

### Package を増やす

- global app / system package を増やすなら `Brewfile` を更新する
- version-managed tool を増やすなら `mise.toml` の `[tools]` を更新する

例:

```toml
[tools]
deno = "2"
node = "lts"
python = "3.13"
```

### dotfile を増やす

`config/` 配下にファイルを追加して、`mise.toml` の `[dotfiles]` に target と
source を足します。

たとえば:

```toml
[dotfiles]
"~/.config/git/ignore" = { source = "config/git/ignore", mode = "symlink" }
```

## Notes

- `mise` 自身は空のマシンでは自分自身を入れられないので、初回だけ
  Homebrew 経由で入れます
- Homebrew 配下の所有者がずれているマシンでは `brew bundle` が失敗します。
  その場合は `setup.sh` が表示する `sudo chown -R ...` を一度実行してください
- 一部の Homebrew package / cask が失敗しても、`setup.sh` は残りの設定適用を続行します
- `mise trust` が必要なのは、この repo の `mise.toml` が `[dotfiles]` を使うためです
- `mise dotfiles` は experimental なので、この repo では `MISE_EXPERIMENTAL=1`
  を付けて実行します
- `mise dotfiles` は symlink モードで使っているので、VS Code や Warp からの編集も
  repo 側にそのまま反映されます
- この repo は `aarch64-darwin` / Apple Silicon を前提にしています

## Verification

setup 変更後は次を実行します。

```bash
shfmt -w setup.sh
bash -n setup.sh
```

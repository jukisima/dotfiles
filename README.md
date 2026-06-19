# dotfiles

Nix をまだ知らない前提で、最初の 1 歩だけに絞った雛形です。

この構成は `home-manager` の standalone 版です。macOS 全体を触る `nix-darwin` はまだ使わず、まずは「自分のホームディレクトリに dotfiles と CLI ツールを入れる」ことだけをやります。

## Files

- `flake.nix`: Nix の入口
- `home.nix`: 普段いじる設定
- `config/vscode/settings.json`: VS Code の user settings
- `config/nix-dots/example.conf`: repo に置いたまま配るサンプル dotfile

## Bootstrap

新しいマシンでは、この repo を clone したあとにまず次を実行します。

```bash
./bootstrap.sh
```

このスクリプトは次をやります。

- Nix が未導入なら公式 macOS installer で入れる
- `~/.config/nix/nix.conf` で `nix-command` と `flakes` を有効化する
- Home Manager を `-b backup` 付きで反映する

## First run

1. flakes を有効化する

   `~/.config/nix/nix.conf` に次を入れます。

   ```conf
   experimental-features = nix-command flakes
   ```

2. この repo で最初の反映をする

   ```bash
   nix run github:nix-community/home-manager/release-26.05 -- switch -b backup --impure --flake path:.#default
   ```

3. 2 回目以降はこれで反映できます

   ```bash
   home-manager switch --impure --flake path:.#default
   ```

## What this template does

- `ripgrep` を入れる
- `starship` を入れて zsh に組み込む
- `vscode` と `codex` を入れる
- `helix` を Home Manager で管理する
- `zed-editor` を入れる
- `google-chrome` を入れる
- VS Code 本体を `programs.vscode` で管理し、`config/vscode/settings.json` を macOS の user settings にリンクする
- Warp の `settings.toml` を `~/.warp/settings.toml` として管理する
- `syncthing` を入れて、自動起動する service として有効化する
- `typst` と `jdk` を入れる
- `antigravity-cli` を入れる
- `mystmd` を入れる
- `devenv` を入れる
- `fdupes` と `rsync` を入れる
- `shfmt` を入れる
- `warp-terminal` を入れる
- `JetBrainsMono Nerd Font` を入れる
- `Alegreya`、`Alcarin Tengwar`、`Fira Code`、`Hack`、`LXGW WenKai TC` を入れる
- `git` と `zshrc` を Home Manager で管理する
- zsh plugin 管理は `antidote` ではなく Home Manager 標準の zsh / zoxide オプションに寄せる
- `config/nix-dots/example.conf` を `~/.config/nix-dots/example.conf` にリンクする

## First edits

最初は `home.nix` だけ触れば十分です。

### Package を増やす

```nix
home.packages = with pkgs; [
  antigravity-cli
  codex
  devenv
  fdupes
  jdk
  mystmd
  ripgrep
  rsync
  starship
  fd
  jq
  syncthing
  typst
];
```

VS Code 自体は `home.packages` ではなく `programs.vscode` で管理しています。`settings.json` は `~/Library/Application Support/Code/User/settings.json` から repo の `config/vscode/settings.json` へリンクしているので、VS Code から編集した内容も repo 側にそのまま反映されます。

### dotfile を増やす

```nix
xdg.configFile."git/ignore".source = ./config/git/ignore;
```

すると repo 内の `config/git/ignore` が `~/.config/git/ignore` に配置されます。

## Notes

- `home.stateVersion = "26.05";` は最初に作った世代の互換性用です。普段はむやみに変えません。
- `programs.git.enable = true;` と `programs.zsh.enable = true;` を使っているので、既存の `~/.gitconfig` と `~/.zshrc` がある場合は初回反映時に衝突します。README の最初のコマンドのように `-b backup` を付けると退避しながら反映できます。
- VS Code の既存 `settings.json` がある場合は、初回反映後に repo の `config/vscode/settings.json` へのリンクへ置き換わります。
- VS Code の設定リンク先は `DOTFILES_REPO` を優先し、未設定なら `home-manager switch` を実行したときの `PWD` を使います。普段どおり repo 直下で `home-manager switch --impure --flake path:.#default` を実行すれば問題ありません。repo 外から `path:/abs/path#default` で反映する場合は、あわせて `DOTFILES_REPO=/abs/path/to/repo` を渡してください。
- Warp の既存 `~/.warp/settings.toml` がある場合も、初回反映後に Home Manager 管理版へ置き換わります。
- `services.syncthing.enable = true;` により、macOS では Home Manager が `launchd` agent を作って Syncthing を自動起動します。
- `vscode` と `antigravity-cli` は unfree パッケージなので、この雛形では `flake.nix` でそのパッケージだけ個別に許可しています。
- `google-chrome` も unfree パッケージなので、この repo では `flake.nix` の `allowUnfreePredicate` に個別追加しています。
- `warp-terminal` も unfree です。この repo では Darwin 向けに `7zz` を使う local overlay で APFS DMG 展開を補っています。
- この雛形は `aarch64-darwin` を前提にしています。`homeDirectory` は固定値ではなく、実行時の `HOME` から読み取り、`username` はその basename から導出します。
- そのため、flake を直接使うコマンドには `--impure` が必要です。
- Intel Mac で使うなら、まず `flake.nix` の `system` を直してください。

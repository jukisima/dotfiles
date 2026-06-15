{ config, homeDirectory, pkgs, ... }:
let
  repoRoot =
    let
      configuredRepoRoot = builtins.getEnv "DOTFILES_REPO";
      workingDirectory = builtins.getEnv "PWD";
      hasFlake = dir: dir != "" && builtins.pathExists "${dir}/flake.nix";
    in
    if configuredRepoRoot != "" then
      configuredRepoRoot
    else if hasFlake workingDirectory then
      workingDirectory
    else
      throw ''
        VS Code settings are linked from the working tree.
        Re-run Home Manager from the repo root or set DOTFILES_REPO=/abs/path/to/repo.
      '';

  vscodeSettingsPath = "${repoRoot}/config/vscode/settings.json";

  # Keep JSON syntax checked at evaluation time even though the file stays mutable.
  _validatedVscodeSettings = builtins.fromJSON (builtins.readFile ./config/vscode/settings.json);
in {
  home.username = builtins.baseNameOf homeDirectory;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
    };
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };
  programs.helix = {
    enable = true;
  };
  services.syncthing = {
    enable = true;
  };

  home.packages = with pkgs; [
    alegreya
    alcarin-tengwar
    antigravity
    antigravity-cli
    codex
    devenv
    fdupes
    fira-code
    google-chrome
    hack-font
    jdk
    lxgw-wenkai-tc
    mystmd
    nerd-fonts.jetbrains-mono
    ripgrep
    rsync
    shfmt
    starship
    syncthing
    typst
    warp-terminal
    zed-editor
  ];

  xdg.enable = true;

  home.file."Library/Application Support/Code/User/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink vscodeSettingsPath;
  home.file.".warp/settings.toml".source = ./config/warp/settings.toml;
  xdg.configFile."nix-dots/example.conf".source = ./config/nix-dots/example.conf;
  xdg.configFile."starship.toml".text = ''
    add_newline = false
  '';
}

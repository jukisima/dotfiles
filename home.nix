{ homeDirectory, pkgs, ... }: {
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
    profiles.default.userSettings = builtins.fromJSON (builtins.readFile ./config/vscode/settings.json);
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
  ];

  xdg.enable = true;

  home.file.".warp/settings.toml".source = ./config/warp/settings.toml;
  xdg.configFile."nix-dots/example.conf".source = ./config/nix-dots/example.conf;
  xdg.configFile."starship.toml".text = ''
    add_newline = false
  '';
}

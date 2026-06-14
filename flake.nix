{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      profileName = "default";
      homeDirectory =
        let
          envHome = builtins.getEnv "HOME";
        in
        if envHome != "" then
          envHome
        else
          throw "HOME is not available during flake evaluation. Re-run with --impure.";
      system = "aarch64-darwin";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            antigravity-cli = final.callPackage ./pkgs/antigravity-cli.nix { };
            warp-terminal =
              if final.stdenvNoCC.hostPlatform.isDarwin then
                prev.warp-terminal.overrideAttrs (_old: {
                  unpackPhase = ''
                    runHook preUnpack
                    ${lib.getExe final._7zz} x "$src"
                    runHook postUnpack
                  '';
                })
              else
                prev.warp-terminal;
          })
        ];
        config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) [
            "antigravity"
            "antigravity-cli"
            "google-chrome"
            "vscode"
            "warp-terminal"
          ];
      };
    in {
      homeConfigurations.${profileName} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit homeDirectory;
        };
        modules = [ ./home.nix ];
      };
    };
}

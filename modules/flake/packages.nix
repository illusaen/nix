{
  inputs,
  lib,
  rootPath,
  self,
  ...
}: let
  localPackageNames = [
    "alacritty"
    "bat"
    "gh"
    "git"
    "mactahoe-cursors"
    "mactahoe-gtk-theme"
    "mactahoe-icon-theme"
    "misc-scripts"
    "niri"
    "niri-scripts"
    "starship"
    "ytdlp"
    "zathura"
    "zed"
    "zsh"
  ];
in {
  flake-file.inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
  };

  imports = [inputs.pkgs-by-name-for-flake-parts.flakeModule];

  flake = {
    overlays.default = _final: prev: {
      local = lib.genAttrs localPackageNames (
        name: let
          system = prev.stdenv.hostPlatform.system;
          packageSet = self.legacyPackages.${system};
        in
          packageSet.${name} or self.packages.${system}.${name}
      );
    };
  };

  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [self.overlays.default];
    };
  in {
    _module.args.pkgs = pkgs;
    pkgsDirectory = rootPath + /packages;

    # Placing long building packages into packages for gh workflow to build and cache
    legacyPackages = {
      llama-cpp = pkgs.llama-cpp.override {cudaSupport = true;};
      inherit (pkgs) bambu-studio;
      noctalia = inputs.noctalia.packages.${system}.default;
    };
  };

  flake.modules.generic.package-overlay = {
    nixpkgs.overlays = [self.overlays.default];
  };
}

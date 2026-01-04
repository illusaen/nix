{
  description = "shared flake-parts template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{
      flake-parts,
      git-hooks-nix,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
      ];

      imports = [
        git-hooks-nix.flakeModule
        treefmt-nix.flakeModule
        flake-parts.flakeModules.easyOverlay
      ];

      perSystem =
        { config, pkgs, ... }:
        {
          overlayAttrs = {
            inherit (config.packages) default;
          };

          treefmt = {
            settings.global = {
              on-unmatched = "debug";
              excludes = [
                ".git"
                "*.lock"
                ".gitignore"
              ];
            };
            programs = {
              clang-format.enable = true;
            };
          };

          pre-commit.settings.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            clang-tidy.enable = true;
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
            inputsFrom = [
              config.treefmt.build.devShell
              config.pre-commit.devShell
            ];
            packages = with pkgs; [
              stdenv
              gnumake
              clang-tools
              cmake
              clang
              pkg-config
              gdb
              valgrind
            ];
          };
        };
    };
}

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
      ];

      perSystem =
        { config, pkgs, ... }:
        rec {
          packages = {
            muddle = pkgs.stdenv.mkDerivation {
              name = "muddle";
              src = fetchTarball {
                url = "https://github.com/demonnic/muddler/releases/download/1.1.0/muddle-shadow-1.1.0.tar";
                sha256 = "1rn05k4mvp1121lyflqpvn2zjbng82r8xm7i6g1vhnx45kcshpk8";
              };
              phases = [
                "installPhase"
              ];
              installPhase = ''
                mkdir -p $out/{bin,lib}
                cp -r $src/bin $out/
                cp -r $src/lib $out/
              '';
            };
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
              stylua.enable = true;
            };
          };

          pre-commit.settings.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            lua-ls.enable = true;
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
              lua5_4_compat
              zulu23
              stylua
            ];
            buildInputs = [ packages.muddle ];
          };
        };
    };
}

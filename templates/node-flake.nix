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
        let
          initPnpmScript = pkgs.writeShellScript "init-pnpm.sh" ''
            function _pnpm-install()
            {
              # Avoid running "pnpm install" for every shell.
              # Only run it when the "package-lock.json" file or nodejs version has changed.
              # We do this by storing the nodejs version and a hash of "package-lock.json" in node_modules.
              local ACTUAL_PNPM_CHECKSUM="$(${pkgs.pnpm}/bin/pnpm --version):$(${pkgs.nix}/bin/nix-hash --type sha256 pnpm-lock.yaml)"
              local PNPM_CHECKSUM_FILE="./node_modules/pnpm-lock.yaml.checksum"
              if [ -f "$PNPM_CHECKSUM_FILE" ]
                then
                  read -r EXPECTED_PNPM_CHECKSUM < "$PNPM_CHECKSUM_FILE"
                else
                  EXPECTED_PNPM_CHECKSUM=""
              fi

              if [ "$ACTUAL_PNPM_CHECKSUM" != "$EXPECTED_PNPM_CHECKSUM" ]
              then
                if ${pkgs.pnpm}/bin/pnpm install
                then
                  echo "$ACTUAL_PNPM_CHECKSUM" > "$PNPM_CHECKSUM_FILE"
                else
                  echo "Install failed. Run 'pnpm install' manually."
                fi
              fi
            }

            if [ ! -f package.json ]
            then
              echo "No package.json found. Run 'pnpm init' to create one." >&2
            else
              _pnpm-install
            fi
          '';
        in
        {
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
              prettier = {
                enable = true;
                settings = {
                  bracketSameLine = true;
                  bracketSpacing = true;
                  semi = true;
                  singleQuote = true;
                  trailingComma = "all";
                };
              };
              nixfmt.enable = true;
              statix.enable = true;
              deadnix.enable = true;
            };
          };

          pre-commit.settings.hooks = {
            treefmt = {
              enable = true;
              packageOverrides.treefmt = config.treefmt.build.wrapper;
            };
            eslint = {
              enable = true;
              settings.extensions = "\\.(j|t)sx?$";
            };
          };

          devShells.default = pkgs.mkShell {
            shellHook = ''
              ${config.pre-commit.installationScript}
              source ${initPnpmScript}
            '';
            inputsFrom = [
              config.treefmt.build.devShell
              config.pre-commit.devShell
            ];
            packages = with pkgs; [
              nodejs_25
              bun
              pnpm
            ];
          };
        };
    };
}

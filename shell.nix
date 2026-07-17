{system ? builtins.currentSystem}: let
  sources = import ./npins;
  pkgs = import sources.nixpkgs.outPath {inherit system;};
  inherit (pkgs) lib;
  devshell = import sources.devshell.outPath {
    nixpkgs = pkgs;
  };
  agenixPackage = pkgs.callPackage "${sources.agenix.outPath}/pkgs/agenix.nix" {};
  treefmtCommand = pkgs.writeShellApplication {
    name = "treefmt";
    runtimeInputs = [pkgs.treefmt];
    text = ''
      exec ${lib.getExe pkgs.treefmt} --no-cache "$@"
    '';
  };
in
  devshell.mkShell {
    imports = [
      "${sources.devshell.outPath}/extra/git/hooks.nix"
    ];

    devshell = {
      name = "nix-fleet";
      motd = "$(type -p menu &>/dev/null && menu)";
      packages =
        [
          agenixPackage
          treefmtCommand
        ]
        ++ (with pkgs; [
          alejandra
          colmena
          deadnix
          dix
          nh
          nix-tree
          nixd
          npins
          prek
          ruff
          shellcheck
          statix
        ]);
    };

    commands = [
      {
        package = treefmtCommand;
        help = "Format all files";
      }
      {
        package = pkgs.nh;
        help = "nh builder";
      }
      {
        package = pkgs.nix-tree;
        help = "Interactively browse dependency graphs of Nix derivations";
      }
    ];

    env = [
      {
        name = "TREEFMT_NO_CACHE";
        value = "1";
      }
    ];

    git.hooks = {
      enable = true;
      pre-commit.text = ''
        #!${lib.getExe pkgs.bash}
        exec ${lib.getExe treefmtCommand} --fail-on-change
      '';
    };
  }

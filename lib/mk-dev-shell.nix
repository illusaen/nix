{
  inputs,
  pkgs,
}: let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  devshell = inputs.devshell.legacyPackages.${system};
  treefmtCommand = pkgs.writeShellApplication {
    name = "treefmt";
    runtimeInputs = with pkgs; [
      alejandra
      deadnix
      ruff
      shellcheck
      statix
      treefmt
    ];
    text = ''
      exec ${lib.getExe pkgs.treefmt} \
        --tree-root . \
        --walk filesystem \
        --no-cache \
        "$@"
    '';
  };
  testsCommand = pkgs.writeShellApplication {
    name = "tests";
    text = ''
      exec nix flake check "$@"
    '';
  };
  deployCommand = pkgs.writeShellApplication {
    name = "deploy";
    runtimeInputs = [
      inputs.colmena.packages.${system}.colmena
      pkgs.coreutils
      pkgs.dix
      pkgs.gawk
      pkgs.gnugrep
      pkgs.hostname
      pkgs.nix
    ];
    text = ''
      exec ${../bin/deploy} "$@"
    '';
  };
  shell = devshell.mkShell {
    imports = [
      "${devshell.extraModulesPath}/git/hooks.nix"
    ];

    devshell = {
      name = "nix-fleet";
      motd = "$(type -p menu &>/dev/null && menu)";
      packages =
        [
          inputs.agenix.packages.${system}.agenix
          inputs.colmena.packages.${system}.colmena
        ]
        ++ (with pkgs; [
          alejandra
          deadnix
          dix
          nixd
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
      {
        package = testsCommand;
        help = "Run flake checks";
      }
      {
        package = deployCommand;
        help = "Build or deploy fleet hosts";
      }
    ];

    git.hooks = {
      enable = true;
      pre-commit.text = ''
        #!${lib.getExe pkgs.bash}
        exec ${lib.getExe treefmtCommand} --fail-on-change
      '';
    };
  };
in {
  deploy = deployCommand;
  formatter = treefmtCommand;
  inherit shell;
}

{
  inputs,
  system,
}: let
  rawFleet = import ../fleet;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  inherit (pkgs) lib;
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
  deployCommand = hostName:
    pkgs.writeShellApplication {
      name = hostName;
      text = ''
        exec ./bin/deploy "$@" ${lib.escapeShellArg hostName}
      '';
    };
  deployCommands =
    map
    (hostName: {
      package = deployCommand hostName;
      help = "Deploy ${hostName}";
    })
    (builtins.attrNames rawFleet.hosts);
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
          treefmtCommand
        ]
        ++ (with pkgs; [
          alejandra
          deadnix
          dix
          nh
          nix-tree
          nixd
          ruff
          shellcheck
          statix
        ]);
    };

    commands =
      [
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
      ]
      ++ deployCommands;

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
  };
in {
  formatter = treefmtCommand;
  inherit shell;
}

{system ? builtins.currentSystem}: let
  sources = import ./npins;
  rawFleet = import ./fleet;
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
      ./bin/check
      nix-build ci.nix -A plain-eval --no-out-link
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
          help = "Run ci tests";
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
  }

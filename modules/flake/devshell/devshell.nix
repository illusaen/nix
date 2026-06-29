{inputs, ...}: {
  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    inputs.nixpkgs.follows = "nixpkgs-unstable";
  };

  imports = [inputs.devshell.flakeModule];

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devshells.default = {
      commands = [
        {
          package = config.treefmt.build.wrapper;
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
      packages =
        config.pre-commit.settings.enabledPackages
        ++ (with pkgs; [
          nixd
        ]);
      env = [
        {
          name = "TREEFMT_NO_CACHE";
          value = "1";
        }
      ];
      # devshell.startup.load-opnix.text = "load-opnix";
      devshell.motd = "$(type -p menu &>/dev/null && menu)";
    };
  };
}

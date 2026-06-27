{inputs, ...}: {
  flake-file.inputs.git-hooks-nix.url = "github:cachix/git-hooks.nix";

  imports = [
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings = {
      package = pkgs.prek;
      hooks.treefmt = {
        enable = true;
        package = config.treefmt.build.wrapper;
      };
    };

    devshells.default = {
      packages = config.pre-commit.settings.enabledPackages;
      devshell.startup.pre-commit.text = config.pre-commit.installationScript;
    };
  };
}

{
  inputs,
  lib,
  ...
}: let
  treefmtConfig = {
    projectRootFile = ".git/config";
    programs = {
      fish_indent.enable = true;
      deadnix.enable = true;
      alejandra.enable = true;
      statix.enable = true;
      shellcheck.enable = true;
      toml-sort.enable = true;
      ruff = {
        check = true;
        format = true;
      };
    };
    settings.global = {
      on-unmatched = "debug";
      excludes = [
        ".secrets/**"
        "*.editorconfig"
        "*.envrc"
        "*.gitconfig"
        "*.gitignore"
        "*flake.lock"
        "*.svg"
        "*.png"
        "*.gif"
        "*.ico"
        "*.jpg"
        "*.webp"
        "*.conf"
        "*.age"
        "*.pub"
        "*.asc"
        "*.org"
        "*.zsh"
        "*.kdl"
        "*.txt"
        "*.tmpl"
        "*.jwe"
        "*.xml"
        "*.dds"
        "*.diff"
        "*.bin"
        # Underscore-prefixed files/dirs are ignored by the module auto-import system
        "**/_*/**"
        "**/_*"
      ];
    };
    settings.formatter.shellcheck.options = [
      "-s"
      "bash"
    ];
  };
in {
  flake-file.inputs.treefmt-nix.url = "github:numtide/treefmt-nix";

  flake-file.formatter = pkgs:
    pkgs.writeShellApplication {
      name = "treefmt-flake-file";
      runtimeInputs = [pkgs.treefmt];
      text = ''
        exec ${lib.getExe pkgs.treefmt} \
          --config-file=${inputs.treefmt-nix.lib.mkConfigFile pkgs treefmtConfig} \
          --tree-root . \
          --walk filesystem \
          --no-cache \
          "$@"
      '';
    };

  imports = [inputs.treefmt-nix.flakeModule];

  perSystem = {config, ...}: {
    treefmt =
      treefmtConfig
      // {
        flakeCheck = false;
      };

    devshells.default.packagesFrom = [
      config.treefmt.build.devShell
    ];
  };
}

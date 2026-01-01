# Fish shell configuration
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.fish;
  inherit (lib) mkIf;
in
{
  options.modules.fish = {
    enable = lib.mkEnableOption "fish shell" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      shellAbbrs = rec {
        gst = "git status";
        gc = "git commit";
        gcm = "git commit -m";
        gco = "git checkout";
        ga = "git add -A";
        gm = "git merge";
        gl = "git log";
        gd = "git diff";
        gb = "git branch";
        gpl = "git pull";
        gp = "git push";
        gpc = "git push -u origin (git rev-parse --abbrev-ref HEAD)";
        gpf = "git push --force-with-lease";
        gbc = "git nb";

        n = "nix";
        nd = "nix develop -c $SHELL";
        ns = "nix shell";
        nsn = "nix shell nixpkgs#";
        nb = "nix build";
        nbn = "nix build nixpkgs#";
        nf = "nix flake";

        rebuild = if pkgs.stdenv.isDarwin then "nh darwin switch ." else "nh os switch .";
        rehome = "nh home switch .";
      };
      shellAliases = {
      };
      functions = {
        fish_greeting = "";
      };

    };
  };
}

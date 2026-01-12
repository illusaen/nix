# CLI tools bundle - common command-line utilities
{
  config,
  lib,
  helpers,
  pkgs,
  ...
}:
let
  cfg = config.modules.cli;
in
{
  options.modules.cli = {
    enable = helpers.mkTrueOption "CLI tools bundle";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      nixfmt
      ripgrep
      sd
      unzip
    ];
  };
}

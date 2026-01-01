# CLI tools bundle - common command-line utilities
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.cli;
in
{
  options.modules.cli = {
    enable = lib.mkEnableOption "CLI tools bundle" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      eza
      nixfmt-rfc-style
      ripgrep
      sd
      unzip
    ];
  };
}

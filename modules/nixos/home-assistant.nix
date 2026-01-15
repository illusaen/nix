# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  inherit (vars) name seedbox;
  cfg = config.modules.ha;
in
{
  options.modules.ha = {
    enable = lib.mkEnableOption "home assistant nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
      };
    };
  };
}

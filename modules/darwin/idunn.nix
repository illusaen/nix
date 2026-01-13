# Base Darwin module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.idunn;
in
{
  options.modules.idunn = {
    enable = lib.mkEnableOption "idunn darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    homebrew.masApps = {
      "Tailscale" = 1475387142;
    };

    system = {
      keyboard.remapCapsLockToControl = true;
      defaults = {
        NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
        dock.tilesize = 48;
        dock.largesize = 64;
      };
    };
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}

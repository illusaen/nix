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
    system.keyboard.remapCapsLockToControl = true;
    system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
    security.pam.services.sudo_local.touchIdAuth = true;
  };
}

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
  cfg = config.modules.jellyfin;
in
{
  options.modules.jellyfin = {
    enable = lib.mkEnableOption "jellyfin nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jellyfin-ffmpeg ];

    services.jellyfin = {
      enable = true;
      openFirewall = true;
      user = name;
      group = seedbox.group;
    };
  };
}

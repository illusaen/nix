# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  pkgs,
  vars,
  ...
}:
let
  inherit (vars) name group;
  cfg = config.modules.navidrome;
in
{
  options.modules.navidrome = {
    enable = mkEnableOption "navidrome nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      enable = true;
      openFirewall = true;
      user = name;
      inherit group;
      settings = {
        LogLevel = "DEBUG";
        Scanner.Schedule = "@every 24h";
        TranscodingCacheSize = "150MiB";
        MusicFolder = "/mnt/hdd/music";
      };
    };
  };
}

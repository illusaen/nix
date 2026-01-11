# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  vars,
  pkgs,
  ...
}:
let
  inherit (vars) name seedbox;
  inherit (seedbox) hd domain group;
  cfg = config.modules.transmission;
in
{
  options.modules.transmission = {
    enable = lib.mkEnableOption "transmission nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.transmission = with pkgs; {
      enable = true;
      package = transmission_4;
      webHome = flood-for-transmission;
      openRPCPort = true;
      openFirewall = true;
      downloadDirPermissions = "770";
      user = name;
      inherit group;
      settings = {
        umask = 2;
        watch-dir-enabled = true;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist = "127.0.0.1,192.168.*.*";
        rpc-host-whitelist = "*.${domain},${domain}";
        trash-original-torrent-files = true;
        download-dir = "/mnt/${lib.toLower hd.misc}/books";
      };
    };
  };
}

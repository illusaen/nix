# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  vars,
  ...
}:
let
  inherit (vars) name group seedbox;
  inherit (seedbox) hd domain;
  cfg = config.modules.transmission;
in
{
  options.modules.transmission = {
    enable = mkEnableOption "transmission nixos configuration";
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

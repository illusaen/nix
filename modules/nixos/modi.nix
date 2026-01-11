{
  config,
  lib,
  inputs,
  vars,
  ...
}:
let
  inherit (vars) name group seedbox;
  inherit (seedbox) hd domain ip;
  cfg = config.modules.modi;
in
{
  imports = [
    inputs.opnix.nixosModules.default
    ../system.nix
  ];

  options.modules.modi = {
    enable = mkEnableOption "modi nixos configuration";
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

    services.nginx =
      let
        hosts =
          {
            transmission = "http://127.0.0.1:${toString config.services.transmission.settings.rpc-port}";
            blocky = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
            jellyfin = "http://127.0.0.1:8096";
            navidrome = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
          }
          |> lib.mapAttrs' (
            name: value:
            lib.nameValuePair "${name}.${domain}" {
              locations."/" = {
                proxyPass = value;
                proxyWebsockets = true;
              };
            }
          );
      in
      {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts = hosts;
      };
  };
}

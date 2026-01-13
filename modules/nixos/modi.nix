{
  config,
  lib,
  inputs,
  vars,
  pkgs,
  ...
}:
let
  inherit (vars) name seedbox;
  cfg = config.modules.modi;
in
{
  imports = [
    ../system.nix
  ];

  options.modules.modi = {
    enable = lib.mkEnableOption "modi nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      permitCertUid = "caddy";
    };
    networking.firewall = {
      allowedUDPPorts = [ config.services.tailscale.port ];
      trustedInterfaces = [ "tailscale0" ];
    };

    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    services.caddy =
      let
        blockyHttp = config.services.grafana.settings.server;
        hosts = {
          transmission = "127.0.0.1:${toString config.services.transmission.settings.rpc-port}";
          blocky = "http://${toString blockyHttp.http_addr}:${toString blockyHttp.http_port}";
          jellyfin = "127.0.0.1:8096";
          navidrome = "127.0.0.1:${toString config.services.navidrome.settings.Port}";
        };
      in
      {
        enable = true;
        # virtualHosts."${seedbox.hostName}.tail99b7d3.ts.net".extraConfig = ''
        #   reverse_proxy /transmission* 127.0.0.1:${toString config.services.transmission.settings.rpc-port}
        #   reverse_proxy /blocky* http://${toString blockyHttp.http_addr}:${toString blockyHttp.http_port}
        #   reverse_proxy /jellyfin* 127.0.0.1:8096
        #   reverse_proxy /navidrome* 127.0.0.1:${toString config.services.navidrome.settings.Port}
        # '';
        virtualHosts = lib.mapAttrs' (
          name: value:
          lib.nameValuePair "${name}.${seedbox.hostName}.tail99b7d3.ts.net" {
            extraConfig = ''
              reverse_proxy ${value}
            '';
          }
        ) hosts;
      };
  };
}

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
    inputs.opnix.nixosModules.default
    ../system.nix
  ];

  options.modules.modi = {
    enable = lib.mkEnableOption "modi nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    services.nginx =
      let
        hosts = {
          transmission = "http://127.0.0.1:${toString config.services.transmission.settings.rpc-port}";
          blocky = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
          jellyfin = "http://127.0.0.1:8096";
          navidrome = "http://127.0.0.1:${toString config.services.navidrome.settings.Port}";
        };

      in
      {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        virtualHosts = lib.mapAttrs' (
          name: value:
          lib.nameValuePair "${name}.${seedbox.domain}" {
            locations."/" = {
              proxyPass = value;
              proxyWebsockets = true;
            };
          }
        ) hosts;
      };
  };
}

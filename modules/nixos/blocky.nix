# Base NixOS module - core configurations enabled by default
{
  config,
  lib,
  vars,
  pkgs,
  ...
}:
let
  inherit (vars.seedbox) domain ip hostName;
  cfg = config.modules.blocky;

  ports = {
    grafana = 3000;
    prometheus = 9001;
    exporter = 9090;
    homeAssistant = config.services.home-assistant.config.http.server_port;
  };
  blocky = {
    dns = 53;
    tls = 853;
    http = 4000;
    https = 443;
  };
in
{
  options.modules.blocky = {
    enable = lib.mkEnableOption "blocky nixos configuration";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      allowPing = true;
      allowedTCPPorts =
        lib.attrValues ports
        ++ lib.attrValues blocky
        ++ [
          80
          8080
        ];
      allowedUDPPorts = [
        blocky.dns
      ];
    };

    services.blocky = {
      enable = true;
      settings = {
        ports = blocky;
        connectIPVersion = "v4";
        upstreams.groups.default = [
          "1.1.1.1"
          "8.8.8.8"
          "8.8.4.4"
        ];
        bootstrapDns = {
          upstream = "8.8.8.8";
        };
        customDNS = {
          mapping."${domain}" = "${ip}";
          filterUnmappedTypes = false;
        };
        caching = {
          minTime = "5m";
          maxTime = "30m";
          prefetching = true;
        };
        prometheus.enable = true;
        blocking = {
          denylists = {
            ads = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
              "https://mirror1.malwaredomains.com/files/justdomains"
              "http://sysctl.org/cameleon/hosts"
              "https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist"
              "https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt"
            ];
          };
          clientGroupsBlock.default = [
            "ads"
          ];
        };
      };
    };

    services.grafana = {
      enable = true;
      declarativePlugins = [ pkgs.grafanaPlugins.grafana-piechart-panel ];
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus - ${hostName}";
            type = "prometheus";
            url = "http://127.0.0.1:${toString ports.prometheus}";
            access = "proxy";
            isDefault = true;
          }
        ];
        dashboards.settings.providers = [
          {
            name = "Blocky";
            options.path = ./blocky_grafana.json;
          }
        ];
      };
      settings.panels.disable_sanitize_html = true;
      settings.server = {
        http_addr = "0.0.0.0";
        http_port = ports.grafana;
        inherit domain;
      };
    };

    services.prometheus = {
      enable = true;
      port = ports.prometheus;
      exporters.node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = ports.exporter;
      };
      scrapeConfigs = [
        {
          job_name = "blocky";
          static_configs = [
            { targets = [ "127.0.0.1:${toString blocky.http}" ]; }
          ];
        }
      ];
    };
  };
}

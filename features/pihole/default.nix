let
  serviceSecrets = {hosts, ...}:
    map (hostName: {
      secret = "hosts/${hostName}/pihole-web-password.age";
      inherit hostName;
    })
    hosts;
in {
  inherit serviceSecrets;

  tests.serviceSecrets =
    serviceSecrets {
      hosts = ["huginn" "odin"];
    }
    == [
      {
        secret = "hosts/huginn/pihole-web-password.age";
        hostName = "huginn";
      }
      {
        secret = "hosts/odin/pihole-web-password.age";
        hostName = "odin";
      }
    ];

  modules.nixos = {
    config,
    host,
    lib,
    options,
    serviceLib,
    fleet,
    ...
  }: let
    service = serviceLib.requireRoutedService host "pihole";
    secretFile = ../../secrets/hosts/${host.name}/pihole-web-password.age;
  in
    lib.mkMerge [
      {
        services = {
          pihole-ftl = {
            enable = true;
            openFirewallDNS = true;
            openFirewallWebserver = true;
            settings = {
              "webserver.api" = {
                cli_pw = true;
                prettyJSON = true;
              };
              dns = {
                inherit (service) port;
                upstreams = ["9.9.9.9" "1.1.1.1" "8.8.8.8"];
                hosts = [""];
              };
              "dns.domain".name = fleet.domain;
            };
          };
          pihole-web = {
            enable = true;
            ports = [
              "80r"
              "443s"
            ];
          };
        };
      }
      (lib.mkIf (builtins.pathExists secretFile) {
        age.secrets.pihole-web-password = {
          file = secretFile;
          owner = "pihole";
          group = "pihole";
        };

        systemd.services.pihole-set-web-password = {
          description = "Set Pi-hole web password from agenix";
          after = ["pihole-ftl.service"];
          requires = ["pihole-ftl.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            Group = "root";
          };
          script = ''
            ${config.services.pihole-ftl.pihole}/bin/pihole setpassword "$(<${config.age.secrets.pihole-web-password.path})"
          '';
        };
      })
      (lib.mkIf (options ? persist) {
        persist.directories = [
          {
            directory = config.services.pihole-ftl.stateDirectory;
            user = "pihole";
            group = "pihole";
            mode = "0700";
          }
          {
            directory = config.services.pihole-ftl.logDirectory;
            user = "pihole";
            group = "pihole";
            mode = "0700";
          }
        ];
      })
    ];
}

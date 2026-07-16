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
    ...
  }: let
    service = host.services.pihole;
    enabled = service.role == "primary" || service.role == "backup";
    secretFile = ../../secrets/hosts/${host.name}/pihole-web-password.age;
  in {
    config = lib.mkIf enabled (lib.mkMerge [
      {
        assertions = [
          {
            assertion = service.protocol == "tcp" || service.protocol == "udp";
            message = "pihole expects a DNS transport protocol";
          }
        ];

        services = {
          pihole-ftl = {
            enable = true;
            openFirewallDNS = true;
            openFirewallWebserver = true;
            settings.webserver.api.cli_pw = true;
          };
          pihole-web = {
            enable = true;
            ports = [80];
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
            directory = "/etc/pihole";
            user = "pihole";
            group = "pihole";
            mode = "0700";
          }
          {
            directory = "/var/lib/pihole";
            user = "pihole";
            group = "pihole";
            mode = "0700";
          }
          {
            directory = "/var/log/pihole";
            user = "pihole";
            group = "pihole";
            mode = "0700";
          }
        ];
      })
    ]);
  };
}

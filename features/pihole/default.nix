{...}: {
  imports = [];

  modules.nixos = {
    host,
    lib,
    ...
  }: let
    service = host.services.pihole;
  in {
    config = lib.mkIf (service.role == "primary") {
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
        };
        pihole-web.enable = true;
      };
    };
  };
}

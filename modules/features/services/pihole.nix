{
  flake.modules.nixos.pihole = {
    services = {
      pihole-ftl = {
        enable = true;
        openFirewallDNS = true;
      };
      pihole-web.enable = true;
    };
  };
}

{
  flake.modules.nixos.tailscale = {config, ...}: {
    services.tailscale.enable = true;
    # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
    # This avoids the "iptables-compat" translation layer issues.
    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    networking.nftables.enable = true;
    networking.firewall = {
      enable = true;
      # Always allow traffic from your Tailscale network
      trustedInterfaces = ["tailscale0"];
      # Allow the Tailscale UDP port through the firewall
      allowedUDPPorts = [config.services.tailscale.port];
    };

    persist.directories = ["/var/lib/tailscale"];
  };

  flake.modules.nixos.tailscale-systray = {config, ...}: {
    systemdAutostart = [
      (let
        inherit (config.services.tailscale) package;
      in {
        inherit package;
        name = "tailscale-systray";
        exec = "${package} systray";
      })
    ];
  };

  flake.modules.darwin.tailscale.homebrew.masApps.Tailscale = 1475387142;
}

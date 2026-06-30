{
  flake.modules.nixos.tailscale = {
    config,
    lib,
    host,
    ...
  }: {
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

    systemd.user.services = lib.mkIf (host.tags.role == "desktop") {
      tailscale-systray = {
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        requires = ["graphical-session-pre.target"];
        after = [
          "graphical-session.target"
          "graphical-session-pre.target"
        ];
        description = "Official Tailscale systray application for Linux";
        serviceConfig.ExecStart = "${lib.getExe config.services.tailscale.package} systray";
      };
    };

    persist.directories = ["/var/lib/tailscale"];
  };

  flake.modules.darwin.tailscale.homebrew.masApps.Tailscale = 1475387142;
}

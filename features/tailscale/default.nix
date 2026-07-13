_: {
  imports = [];

  modules.nixos = {
    config,
    lib,
    options,
    ...
  }: {
    config = lib.mkMerge [
      {
        services.tailscale.enable = true;

        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

        networking = {
          nftables.enable = true;
          firewall = {
            enable = true;
            trustedInterfaces = ["tailscale0"];
            allowedUDPPorts = [config.services.tailscale.port];
          };
        };
      }
      (lib.mkIf (options ? persist) {
        persist.directories = ["/var/lib/tailscale"];
      })
    ];
  };

  modules.darwin = _: {
    homebrew.masApps.Tailscale = 1475387142;
  };
}

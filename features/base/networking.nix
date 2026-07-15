{
  modules.nixos = {
    fleet,
    host,
    lib,
    options,
    ...
  }: let
    staticInterfaces = host.networkInterfaces or {};
    hasStaticInterfaces = staticInterfaces != {};
    mkNetwork = name: interface:
      lib.nameValuePair "10-${name}" {
        matchConfig.Name = name;
        address = lib.optional (interface ? ipv4) interface.ipv4 ++ lib.optional (interface ? ipv6) interface.ipv6;
        routes = [
          {Gateway = "192.168.1.1";}
          {Gateway = "fe80::1";}
        ];
        linkConfig.RequiredForOnline = "routable";
      };
  in
    {
      networking = {
        hostName = host.name or null;
        inherit (fleet) domain;
        inherit (host) hostId;
        networkmanager.enable = !hasStaticInterfaces;
        useDHCP = !hasStaticInterfaces;
        useNetworkd = hasStaticInterfaces;
      };

      systemd.network = lib.mkIf hasStaticInterfaces {
        enable = true;
        wait-online.anyInterface = true;
        networks = lib.mapAttrs' mkNetwork staticInterfaces;
      };
    }
    // lib.mkIf (options ? persist && !hasStaticInterfaces) {
      persist.directories = ["/etc/NetworkManager/system-connections"];
    };

  modules.darwin = {host, ...}: {
    networking.computerName = host.name or host.targetHost;
  };
}

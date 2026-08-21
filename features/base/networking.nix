{
  modules.nixos = {
    fleet,
    fleetLib,
    host,
    lib,
    options,
    ...
  }: let
    staticInterfaces = host.networkInterfaces or {};
    hasStaticInterfaces = staticInterfaces != {};
    hostsWithIpv4 = lib.filterAttrs (name: knownHost:
      name != host.name && fleetLib.hostIps "ipv4" knownHost != [])
    fleet.hosts;
    fleetHosts = lib.mapAttrs' (_name: knownHost:
      lib.nameValuePair (builtins.head (fleetLib.hostIps "ipv4" knownHost)) [
        knownHost.name
        "${knownHost.name}.${fleet.domain}"
      ])
    hostsWithIpv4;
    mkNetwork = name: interface:
      lib.nameValuePair "10-${name}" {
        matchConfig.Name = name;
        address =
          lib.optional ((interface.ipv4 or null) != null) interface.ipv4
          ++ lib.optional ((interface.ipv6 or null) != null) interface.ipv6;
        routes = [
          {Gateway = "192.168.1.1";}
          {Gateway = "fe80::1";}
        ];
        linkConfig.RequiredForOnline = "routable";
      };
  in
    lib.mkMerge [
      {
        networking = {
          hostName = host.name or null;
          inherit (fleet) domain;
          inherit (host) hostId;
          hosts = fleetHosts;
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
      (lib.mkIf (options ? persist && !hasStaticInterfaces) {
        persist.directories = ["/etc/NetworkManager/system-connections"];
      })
    ];

  modules.darwin = {host, ...}: {
    networking.computerName = host.name or host.targetHost;
  };
}

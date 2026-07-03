{lib, ...}: {
  flake.modules.nixos.networking = {
    fleet,
    host,
    ...
  }: let
    staticInterfaces = host.networkInterfaces or {};
    hasStaticInterfaces = staticInterfaces != {};
    mkNetwork = name: interface:
      lib.nameValuePair "10-${name}" {
        matchConfig.Name = name;
        address = lib.optional (interface ? ipv4) interface.ipv4 ++ lib.optional (interface ? ipv6) interface.ipv6;
        routes = [{Gateway = "192.168.1.1";} {Gateway = "fe80::1";}];
        linkConfig.RequiredForOnline = "routable";
      };
  in {
    networking = {
      inherit (fleet) domain;
      inherit (host) hostId;
      networkmanager.enable = !hasStaticInterfaces;
      useDHCP = !hasStaticInterfaces;
      useNetworkd = hasStaticInterfaces;
    };

    systemd.network = lib.mkIf hasStaticInterfaces {
      enable = true;
      wait-online.anyInterface = true;
      networks = lib.mapAttrs' mkNetwork host.networkInterfaces;
    };

    persist.directories = lib.optionals (!hasStaticInterfaces) [
      "/etc/NetworkManager/system-connections"
    ];
  };

  flake.modules.darwin.networking = {config, ...}: {networking.computerName = config.networking.hostName;};

  flake.modules.generic.networking = {
    fleet,
    host,
    ...
  }: {
    programs.ssh.knownHosts =
      fleet.hosts
      |> builtins.attrValues
      |> builtins.filter (h: h.name != host.name && h.publicKey != null)
      |> map (h:
        lib.nameValuePair h.name {
          hostNames = [h.name "${h.name}.${fleet.domain}" h.ipv4];
          publicKeyFile = h.publicKey;
        })
      |> builtins.listToAttrs;
  };
}

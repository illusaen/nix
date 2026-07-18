{lib}: let
  inherit (builtins) attrNames concatLists;
  inherit (lib) mapAttrs' nameValuePair pipe;

  roleFor = hostName: service:
    if service.primary == hostName
    then "primary"
    else if builtins.elem hostName (service.backups or [])
    then "backup"
    else null;

  servicesForHost = hostName: services:
    pipe services [
      (builtins.mapAttrs (name: service:
        service
        // {
          inherit name;
          role = roleFor hostName service;
        }))
      builtins.attrValues
      (builtins.filter (s: s.role != null))
    ];

  requireRoutedService = host: name: let
    service = lib.findFirst (service: service.name == name) null (host.services or []);
  in
    if service == null
    then throw "${name} feature requires a routed ${name} service for host '${host.name}'"
    else service;

  portConflictsForHost = hostName: services:
    pipe services [
      (servicesForHost hostName)
      (map (service: {
        key = "${hostName}:${toString service.port}";
        inherit (service) name;
      }))
      (builtins.groupBy (s: s.key))
      (lib.filterAttrs (_groupName: group: lib.length group > 1))
      (builtins.mapAttrs (groupName: group: {
        inherit hostName;
        key = groupName;
        services = builtins.catAttrs "name" group;
      }))
      builtins.attrValues
    ];

  portConflicts = fleet:
    pipe fleet.hosts [
      attrNames
      (map (hostName: portConflictsForHost hostName fleet.services))
      concatLists
    ];

  hostIpv4 = host: let
    addresses = builtins.filter builtins.isString (builtins.catAttrs "ipv4" (builtins.attrValues host.networkInterfaces));
  in
    if addresses == []
    then throw "host '${host.name}' has no static IPv4 address"
    else builtins.head (lib.splitString "/" (builtins.head addresses));

  reverseProxy = fleet: let
    caddy = fleet.services.caddy or (throw "the fleet has no caddy service");
    proxyHost = fleet.hosts.${caddy.primary};
  in {
    address = hostIpv4 proxyHost;
    routes = mapAttrs' (
      serviceName: service: let
        upstreamHost = fleet.hosts.${service.primary};
      in
        nameValuePair "${serviceName}.${upstreamHost.name}.${fleet.domain}" {
          inherit serviceName;
          hostName = upstreamHost.name;
          upstream = "${hostIpv4 upstreamHost}:${toString (service.proxyPort or service.port)}";
        }
    ) (removeAttrs fleet.services ["caddy"]);
  };
in {
  inherit hostIpv4 portConflicts requireRoutedService reverseProxy servicesForHost;
}

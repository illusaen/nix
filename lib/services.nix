{lib}: let
  inherit (builtins) attrNames concatLists;
  inherit (lib) pipe;

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
in {
  inherit portConflicts requireRoutedService servicesForHost;
}

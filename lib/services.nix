{lib}: let
  inherit (builtins) attrNames concatLists;
  inherit (lib) optionals pipe unique;

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

  tagFeatureNames = tags:
    pipe tags [
      (map (tag: let
        match = builtins.match "feature:(.+)" tag;
      in
        if match == null
        then []
        else ["programs-${builtins.head match}"]))
      concatLists
    ];

  derivedHostFeatures = host: let
    tags = host.tags or [];
    isLinux = host.platform == "nixos";
    isDesktop = builtins.elem "desktop" tags;
  in
    unique (
      ["base"]
      ++ optionals isLinux ["boot"]
      ++ optionals isDesktop ["programs-core" "theming"]
      ++ optionals (isLinux && isDesktop) ["desktop-shell"]
      ++ optionals (builtins.elem "gpu:nvidia" tags) ["nvidia"]
      ++ tagFeatureNames tags
      ++ optionals (host.preservation.enable or false) ["preservation"]
    );

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

  routeHosts = fleet:
    builtins.mapAttrs (
      hostName: host: let
        services = servicesForHost hostName fleet.services;
      in
        host
        // {
          inherit services;
          features = unique (derivedHostFeatures host ++ host.features ++ builtins.catAttrs "feature" services);
        }
    )
    fleet.hosts;
in {
  inherit portConflicts requireRoutedService routeHosts;
}

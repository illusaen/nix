{lib ? import ((import ../npins).nixpkgs.outPath + "/lib")}: let
  inherit (builtins) attrNames concatLists filter listToAttrs;
  inherit (lib) optionals unique;

  serviceForHost = hostName: serviceName: service:
    if service.primary == hostName
    then [
      {
        name = serviceName;
        value = service // {role = "primary";};
      }
    ]
    else if builtins.elem hostName (service.backups or [])
    then [
      {
        name = serviceName;
        value = service // {role = "backup";};
      }
    ]
    else [];

  servicesForHost = hostName: services:
    listToAttrs (
      builtins.concatLists (
        map (serviceName: serviceForHost hostName serviceName services.${serviceName})
        (attrNames services)
      )
    );

  routedFeatureNames = routedServices:
    unique (map (name: routedServices.${name}.feature) (attrNames routedServices));

  tagFeatureNames = tags:
    concatLists (
      map (tag: let
        match = builtins.match "feature:(.+)" tag;
      in
        if match == null
        then []
        else ["programs-${builtins.head match}"])
      tags
    );

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

  transportProtocol = protocol:
    if protocol == "http" || protocol == "https"
    then "tcp"
    else protocol;

  servicePortEntriesForHost = hostName: services: let
    routedServices = servicesForHost hostName services;
  in
    map (serviceName: let
      service = routedServices.${serviceName};
      protocol = transportProtocol service.protocol;
      port = toString service.port;
    in {
      inherit hostName port protocol serviceName;
      key = "${hostName}:${protocol}:${port}";
    })
    (attrNames routedServices);

  portConflictsForHost = hostName: services: let
    entries = servicePortEntriesForHost hostName services;
    keys = unique (map (entry: entry.key) entries);
    duplicateKeys =
      filter (
        key:
          builtins.length (filter (entry: entry.key == key) entries) > 1
      )
      keys;
  in
    map (key: {
      inherit hostName key;
      services = map (entry: entry.serviceName) (filter (entry: entry.key == key) entries);
    })
    duplicateKeys;

  portConflicts = fleet:
    builtins.concatLists (
      map (hostName: portConflictsForHost hostName fleet.services)
      (attrNames fleet.hosts)
    );

  routeHosts = fleet:
    builtins.mapAttrs (
      hostName: host: let
        services = servicesForHost hostName fleet.services;
      in
        host
        // {
          inherit services;
          features = unique (derivedHostFeatures host ++ host.features ++ routedFeatureNames services);
        }
    )
    fleet.hosts;
in {
  inherit portConflicts routeHosts servicesForHost;
}

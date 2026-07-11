{fleetLib ? import ./fleet.nix {}}: let
  inherit (builtins) attrNames filter listToAttrs;
  inherit (fleetLib) unique;

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
    unique (map (name: routedServices.${name}.feature or name) (attrNames routedServices));

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

  normalizeHost = hostName: host: let
    preservation =
      if host.preservation.enable or false
      then
        {
          rootSnapshot = "zroot/local/root@blank";
          homeSnapshot = "zroot/local/home@blank";
          persistMount = "/persist";
        }
        // host.preservation
      else host.preservation or {enable = false;};
  in
    host
    // {
      name = hostName;
      platform = fleetLib.platformForSystem host.system;
      privateKey = host.privateKey or "/etc/ssh/ssh_host_ed25519_key";
      publicKey = host.publicKey or (../secrets/hosts + "/${hostName}/host_ed25519.pub");
      inherit preservation;
    };

  routeHosts = fleet:
    builtins.mapAttrs (
      hostName: host: let
        normalizedHost = normalizeHost hostName host;
        services = servicesForHost hostName fleet.services;
      in
        normalizedHost
        // {
          inherit services;
          features = unique ((normalizedHost.features or []) ++ routedFeatureNames services);
        }
    )
    fleet.hosts;
in {
  inherit normalizeHost portConflicts routeHosts routedFeatureNames servicesForHost;
}

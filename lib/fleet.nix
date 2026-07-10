_: let
  inherit (builtins) attrNames concatLists filter hasAttr map;

  unique = values:
    builtins.foldl' (
      seen: value:
        if builtins.elem value seen
        then seen
        else seen ++ [value]
    ) []
    values;

  require = condition: message:
    if condition
    then []
    else [message];

  platformForSystem = system:
    if builtins.match ".*-linux" system != null
    then "nixos"
    else if builtins.match ".*-darwin" system != null
    then "darwin"
    else null;

  duplicates = values: let
    uniqueValues = unique values;
  in
    filter (
      value:
        builtins.length (filter (candidate: candidate == value) values) > 1
    )
    uniqueValues;

  hostInterfaceAddresses = host:
    concatLists (
      map (
        interfaceName: let
          interface = host.networkInterfaces.${interfaceName};
        in
          (
            if interface ? ipv4
            then [
              {
                address = interface.ipv4;
                family = "ipv4";
              }
            ]
            else []
          )
          ++ (
            if interface ? ipv6
            then [
              {
                address = interface.ipv6;
                family = "ipv6";
              }
            ]
            else []
          )
      )
      (attrNames (host.networkInterfaces or {}))
    );

  hostAddressEntries = fleet:
    concatLists (
      map (
        name:
          map (entry: entry // {host = name;})
          (hostInterfaceAddresses fleet.hosts.${name})
      )
      (attrNames fleet.hosts)
    );

  validateHost = fleet: name: host:
    require (hasAttr host.owner fleet.users) "host '${name}' owner '${host.owner}' does not exist"
    ++ require (platformForSystem host.system != null) "host '${name}' has unsupported system '${host.system}'"
    ++ require (host ? targetHost) "host '${name}' is missing targetHost"
    ++ require (!(host.preservation.enable or false) || (host.preservation.disk or null) != null) "host '${name}' enables preservation without a disk"
    ++ concatLists (map (feature:
      require false "host '${name}' lists feature '${feature}' more than once")
    (duplicates (host.features or [])))
    ++ concatLists (map (tag:
      require false "host '${name}' lists tag '${tag}' more than once")
    (duplicates (host.tags or [])));

  validateService = fleet: name: service:
    require (hasAttr service.primary fleet.hosts) "service '${name}' primary host '${service.primary}' does not exist"
    ++ concatLists (map (backup:
      require (hasAttr backup fleet.hosts) "service '${name}' backup host '${backup}' does not exist")
    (service.backups or []))
    ++ require (!(builtins.elem service.primary (service.backups or []))) "service '${name}' lists primary host '${service.primary}' as a backup"
    ++ require (service.port > 0 && service.port < 65536) "service '${name}' port must be between 1 and 65535"
    ++ require (service.protocol == "tcp" || service.protocol == "udp" || service.protocol == "http" || service.protocol == "https") "service '${name}' has invalid protocol '${service.protocol}'";

  validateSecretHostKeys = fleet:
    concatLists (map (name:
      require (builtins.pathExists (../secrets/hosts + "/${name}/host_ed25519.pub")) "host '${name}' is missing secrets/hosts/${name}/host_ed25519.pub")
    (attrNames fleet.hosts));

  validateUniqueHostValues = fleet: let
    names = attrNames fleet.hosts;
    duplicateTargetHosts = duplicates (map (name: fleet.hosts.${name}.targetHost) names);
    hostsWithHostId = filter (name: fleet.hosts.${name} ? hostId) names;
    duplicateHostIds = duplicates (map (name: fleet.hosts.${name}.hostId) hostsWithHostId);
    addressEntries = hostAddressEntries fleet;
    globallyUniqueAddressEntries =
      filter (entry: entry.family != "ipv6" || builtins.substring 0 5 entry.address != "fe80:")
      addressEntries;
    duplicateAddresses = duplicates (map (entry: entry.address) globallyUniqueAddressEntries);
  in
    concatLists (map (targetHost:
      require false "targetHost '${targetHost}' is used by multiple hosts")
    duplicateTargetHosts)
    ++ concatLists (map (hostId:
      require false "hostId '${hostId}' is used by multiple hosts")
    duplicateHostIds)
    ++ concatLists (map (address:
      require false "network address '${address}' is used by multiple hosts")
    duplicateAddresses);

  validate = fleet:
    concatLists (map (name: validateHost fleet name fleet.hosts.${name}) (attrNames fleet.hosts))
    ++ concatLists (map (name: validateService fleet name fleet.services.${name}) (attrNames fleet.services))
    ++ validateSecretHostKeys fleet
    ++ validateUniqueHostValues fleet;

  assertValid = fleet: let
    errors = validate fleet;
  in
    if errors == []
    then fleet
    else throw "fleet validation failed:\n${builtins.concatStringsSep "\n" (map (error: "- ${error}") errors)}";

  platformHosts = platform: hosts:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = hosts.${name};
      })
      (filter (name: hosts.${name}.platform == platform) (attrNames hosts))
    );
in {
  inherit assertValid duplicates hostAddressEntries platformForSystem platformHosts unique validate;
}

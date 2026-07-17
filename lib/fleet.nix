{lib ? import ((import ../npins).nixpkgs.outPath + "/lib")}: let
  inherit (builtins) attrNames concatLists filter hasAttr;
  inherit (lib) pipe unique;

  concatMap = f: values:
    pipe values [
      (map f)
      concatLists
    ];

  require = condition: message:
    if condition
    then []
    else [message];

  duplicates = values:
    pipe values [
      unique
      (filter (
        value:
          builtins.length (filter (candidate: candidate == value) values) > 1
      ))
    ];

  hostInterfaceAddresses = host:
    pipe (host.networkInterfaces or {}) [
      attrNames
      (concatMap (
        interfaceName: let
          interface = host.networkInterfaces.${interfaceName};
        in
          lib.optional ((interface.ipv4 or null) != null) {
            address = interface.ipv4;
            family = "ipv4";
          }
          ++ lib.optional ((interface.ipv6 or null) != null) {
            address = interface.ipv6;
            family = "ipv6";
          }
      ))
    ];

  hostAddressEntries = fleet:
    pipe fleet.hosts [
      attrNames
      (concatMap (
        name:
          map (entry: entry // {host = name;})
          (hostInterfaceAddresses fleet.hosts.${name})
      ))
    ];

  validateHost = fleet: name: host:
    require (hasAttr host.owner fleet.users) "host '${name}' owner '${host.owner}' does not exist"
    ++ require (host ? targetHost) "host '${name}' is missing targetHost"
    ++ require (!(host.preservation.enable or false) || (host.preservation.disk or null) != null) "host '${name}' enables preservation without a disk"
    ++ concatMap (feature:
      require false "host '${name}' lists feature '${feature}' more than once")
    (duplicates (host.features or []))
    ++ concatMap (tag:
      require false "host '${name}' lists tag '${tag}' more than once")
    (duplicates (host.tags or []));

  validateUser = fleet: name: user:
    concatMap (group:
      require (hasAttr group fleet.groups) "user '${name}' references unknown group '${group}'")
    (user.groups or [])
    ++ concatMap (group:
      require false "user '${name}' lists group '${group}' more than once")
    (duplicates (user.groups or []));

  validateGroup = fleet: name: group:
    concatMap (member:
      require (hasAttr member fleet.groups) "group '${name}' references unknown member group '${member}'")
    (group.members or [])
    ++ concatMap (member:
      require false "group '${name}' lists member group '${member}' more than once")
    (duplicates (group.members or []));

  validateService = fleet: name: service:
    require (hasAttr service.primary fleet.hosts) "service '${name}' primary host '${service.primary}' does not exist"
    ++ concatMap (backup:
      require (hasAttr backup fleet.hosts) "service '${name}' backup host '${backup}' does not exist")
    (service.backups or [])
    ++ require (!(builtins.elem service.primary (service.backups or []))) "service '${name}' lists primary host '${service.primary}' as a backup"
    ++ concatMap (backup:
      require false "service '${name}' lists backup host '${backup}' more than once")
    (duplicates (service.backups or []))
    ++ require (service.port > 0 && service.port < 65536) "service '${name}' port must be between 1 and 65535"
    ++ require (service.protocol == "tcp" || service.protocol == "udp" || service.protocol == "http" || service.protocol == "https") "service '${name}' has invalid protocol '${service.protocol}'";

  validateSecretHostKeys = fleet:
    pipe fleet.hosts [
      attrNames
      (concatMap (name:
          require (builtins.pathExists (../secrets/hosts + "/${name}/host_ed25519.pub")) "host '${name}' is missing secrets/hosts/${name}/host_ed25519.pub"))
    ];

  validateUniqueHostValues = fleet: let
    names = attrNames fleet.hosts;
    duplicateTargetHosts = duplicates (map (name: fleet.hosts.${name}.targetHost) names);
    hostsWithHostId = filter (name: fleet.hosts.${name} ? hostId) names;
    duplicateHostIds = duplicates (map (name: fleet.hosts.${name}.hostId) hostsWithHostId);
    addressEntries = hostAddressEntries fleet;
    globallyUniqueAddressEntries = filter (entry: entry.family != "ipv6" || builtins.substring 0 5 entry.address != "fe80:") addressEntries;
    duplicateAddresses = duplicates (map (entry: entry.address) globallyUniqueAddressEntries);
  in
    concatMap (targetHost:
      require false "targetHost '${targetHost}' is used by multiple hosts")
    duplicateTargetHosts
    ++ concatMap (hostId:
      require false "hostId '${hostId}' is used by multiple hosts")
    duplicateHostIds
    ++ concatMap (address:
      require false "network address '${address}' is used by multiple hosts")
    duplicateAddresses;

  validateUniqueUserValues = fleet: let
    names = attrNames fleet.users;
    usersWithUid = filter (name: (fleet.users.${name}.system.uid or null) != null) names;
    duplicateUids = duplicates (map (name: fleet.users.${name}.system.uid) usersWithUid);
  in
    concatMap (uid:
      require false "uid '${toString uid}' is used by multiple users")
    duplicateUids;
in rec {
  userPosixGroups = fleet: userName: let
    user = fleet.users.${userName};
    userGroups = user.groups or [];
  in
    filter (
      name: let
        group = fleet.groups.${name};
      in
        (group.isPosix or false)
        && builtins.any (member: builtins.elem member userGroups) (group.members or [])
    )
    (attrNames fleet.groups);

  assertValid = fleet: let
    errors = validate fleet;
  in
    if errors == []
    then fleet
    else throw "fleet validation failed:\n${builtins.concatStringsSep "\n" (map (error: "- ${error}") errors)}";

  platformHosts = platform: hosts:
    lib.filterAttrs (_name: host: host.platform == platform) hosts;

  validate = fleet:
    pipe [
      (pipe fleet.users [
        attrNames
        (concatMap (name: validateUser fleet name fleet.users.${name}))
      ])
      (pipe fleet.groups [
        attrNames
        (concatMap (name: validateGroup fleet name fleet.groups.${name}))
      ])
      (pipe fleet.hosts [
        attrNames
        (concatMap (name: validateHost fleet name fleet.hosts.${name}))
      ])
      (pipe fleet.services [
        attrNames
        (concatMap (name: validateService fleet name fleet.services.${name}))
      ])
      (validateSecretHostKeys fleet)
      (validateUniqueHostValues fleet)
      (validateUniqueUserValues fleet)
    ] [
      concatLists
    ];
}

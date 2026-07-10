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

  validateHost = fleet: name: host:
    require (hasAttr host.owner fleet.users) "host '${name}' owner '${host.owner}' does not exist"
    ++ require (host.platform == "nixos" || host.platform == "darwin") "host '${name}' has invalid platform '${host.platform}'"
    ++ require (host ? targetHost) "host '${name}' is missing targetHost"
    ++ require (!(host.preservation.enable or false) || (host.preservation.disk or null) != null) "host '${name}' enables preservation without a disk";

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

  validate = fleet:
    concatLists (map (name: validateHost fleet name fleet.hosts.${name}) (attrNames fleet.hosts))
    ++ concatLists (map (name: validateService fleet name fleet.services.${name}) (attrNames fleet.services))
    ++ validateSecretHostKeys fleet;

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
  inherit assertValid platformHosts unique validate;
}

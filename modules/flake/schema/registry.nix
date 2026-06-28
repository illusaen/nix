{
  inputs,
  config,
  rootPath,
  ...
} @ top: let
  genSchema = inputs.gen-schema.lib;
  topConfig = top.config;
in {
  options.fleet.hosts = genSchema.mkInstanceRegistry config.schema.host {
    refs.owner = config.fleet.users;
    extraModules = [
      (
        {config, ...}: {
          secretPath = rootPath + "/secrets/hosts/${config.name}";
          facts = rootPath + "/hosts/${config.name}/facter.json";
          publicKey =
            if config.secretPath != null
            then config.secretPath + "/host_ed25519.pub"
            else null;
        }
      )
    ];
  };
  options.fleet.users = genSchema.mkInstanceRegistry config.schema.user {
    refs.resolvedGroups = config.fleet.groups;
    extraModules = [
      ({config, ...}: {
        secretPath = rootPath + "/secrets/users/${config.name}";
      })
    ];
  };
  options.fleet.groups = genSchema.mkInstanceRegistry config.schema.group {
    refs.members = {
      instances = config.fleet.users;
      deferred = true;
      coerce = groups: _default: member: let
        users = config.fleet.users;
        expand = seen: name: let
          isUser = builtins.hasAttr name users;
          isGroup = builtins.hasAttr name groups;
        in
          if !builtins.isString name
          then [name]
          else if isUser && isGroup
          then throw "Ambiguous member '${name}': both a user and group exist"
          else if isUser
          then [users.${name}]
          else if isGroup
          then
            if builtins.elem name seen
            then
              throw "Group membership cycle: ${
                builtins.concatStringsSep " -> " (seen ++ [name])
              }"
            else
              builtins.concatMap
              (expand (seen ++ [name]))
              groups.${name}.members
          else throw "Unknown user or group '${name}'";
      in
        expand [] member;
    };
    extraModules = [
      ({
        config,
        lib,
        ...
      }: {members = lib.mkAfter (topConfig.fleet.users |> builtins.attrValues |> builtins.filter (user: lib.elem config.name user.groups));})
    ];
  };
}

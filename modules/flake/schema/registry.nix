{
  inputs,
  config,
  rootPath,
  ...
}: let
  genSchema = inputs.gen-schema.lib;
  fleetUsers = config.fleet.users;
in {
  schema.fleet.options.hosts =
    (genSchema.mkInstanceRegistry config.schema.host {
      refs.owner = config.fleet.users;
      extraModules = [
        (
          {
            config,
            lib,
            ...
          }: {
            facter = rootPath + "/modules/system/hosts/${config.name}/facter.json";
            publicKey = rootPath + "/secrets/hosts/${config.name}/host_ed25519.pub";

            moduleNames = lib.flatten (["base" "boot" "hardware" config.owner.name]
              ++ lib.optional (config.tags.gpu or null == "nvidia") "nvidia"
              ++ lib.optional (config.tags.role or null == "desktop") ["desktop-shell" "programs-core" "theming"]
              ++ lib.optional (config.tags.role or null == "server") "services"
              ++ lib.optional (config.tags.features or [] != []) (map (f: "programs-${f}") config.tags.features)
              ++ lib.optional config.preservation.enable "preservation");
          }
        )
      ];
    })
    // {defaultText = {text = "{}";};};
  schema.fleet.options.users =
    (genSchema.mkInstanceRegistry config.schema.user {
      refs.resolvedGroups = config.fleet.groups;
    })
    // {defaultText = {text = "{}";};};
  schema.fleet.options.groups =
    (genSchema.mkInstanceRegistry config.schema.group {
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
        }: {members = lib.mkAfter (fleetUsers |> builtins.attrValues |> builtins.filter (user: lib.elem config.name user.groups));})
      ];
    })
    // {defaultText = {text = "{}";};};
  schema.fleet.options.services =
    (genSchema.mkInstanceRegistry config.schema.service {
      refs.host = config.fleet.hosts;
      refs.backups = config.fleet.hosts;
    })
    // {defaultText = {text = "{}";};};
}

{
  inputs,
  config,
  rootPath,
  ...
}: let
  genSchema = inputs.gen-schema.lib;
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
            secretPath = rootPath + "/secrets/hosts/${config.name}";
            facter = rootPath + "/modules/system/hosts/${config.name}/facter.json";
            publicKey =
              if config.secretPath != null
              then config.secretPath + "/host_ed25519.pub"
              else null;

            moduleNames = lib.flatten (["base" "boot" "hardware" config.owner.name]
              ++ lib.optional (config.tags.role or null == "desktop") ["desktop-shell" "programs" "theming"]
              ++ lib.optional (config.tags.role or null == "server") "services"
              ++ lib.optional config.preservation.enable "preservation");
          }
        )
      ];
    })
    // {defaultText = {text = "{}";};};
  schema.fleet.options.users =
    (genSchema.mkInstanceRegistry config.schema.user {
      refs.resolvedGroups = config.fleet.groups;
      extraModules = [
        ({config, ...}: {
          secretPath = rootPath + "/secrets/users/${config.name}";
        })
      ];
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
          fleet,
          ...
        }: {members = lib.mkAfter (fleet.users |> builtins.attrValues |> builtins.filter (user: lib.elem config.name user.groups));})
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

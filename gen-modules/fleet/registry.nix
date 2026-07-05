{
  genSchema,
  config,
  lib,
  rootPath,
  ...
}: let
  fleetUserRegistry = config.fleet.users;
  fleetGroups = config.fleet.groups;
in {
  schema.fleet.options.hosts =
    (genSchema.mkInstanceRegistry config.schema.host {
      refs.owner = config.fleet.users;
      extraModules = [
        (
          {config, ...}: {
            facter = rootPath + "/gen-modules/fleet/hosts/${config.name}/facter.json";
            publicKey = rootPath + "/secrets/hosts/${config.name}/host_ed25519.pub";

            moduleNames = lib.flatten (["base" "boot" config.owner.name]
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
      extraModules = [
        ({config, ...}: {
          resolvedGroups = let
            groupContainsUser = seen: name:
              if builtins.hasAttr name fleetGroups
              then
                if builtins.elem name seen
                then
                  throw "Group membership cycle: ${
                    builtins.concatStringsSep " -> " (seen ++ [name])
                  }"
                else
                  lib.any
                  (member:
                    member
                    == config.name
                    || lib.elem member config.groups
                    || groupContainsUser (seen ++ [name]) member)
                  fleetGroups.${name}.members
              else if builtins.hasAttr name fleetUserRegistry
              then name == config.name
              else throw "Unknown user or group '${name}'";
            groupHasUser = group:
              groupContainsUser [] group.name;
          in
            fleetGroups
            |> builtins.attrValues
            |> builtins.filter groupHasUser
            |> map (group: group.name)
            |> (groups: config.groups ++ groups);
        })
      ];
    })
    // {defaultText = {text = "{}";};};
  schema.fleet.options.groups =
    (genSchema.mkInstanceRegistry config.schema.group {})
    // {defaultText = {text = "{}";};};
  schema.fleet.options.services =
    (genSchema.mkInstanceRegistry config.schema.service {
      refs.host = config.fleet.hosts;
      refs.backups = config.fleet.hosts;
    })
    // {defaultText = {text = "{}";};};
}

{lib, ...}: {
  debug = true;
  flake.modules.generic.defaults = {host, ...}: {
    nixpkgs.hostPlatform = host.system;
    networking.hostName = host.name;
  };

  flake.modules.nixos.defaults = {
    fleet,
    user,
    ...
  }: let
    isPosixGroup = _name: group: group.isPosix or false;
    posixGroups = lib.filterAttrs isPosixGroup (fleet.groups or {});
    isPosixGroupValue = group: isPosixGroup (group.name or "") group;
    userInGroup = group:
      lib.any (member: member.id_hash == user.id_hash) (group.members or []);
    directResolvedGroups =
      (user.resolvedGroups or [])
      |> builtins.filter isPosixGroupValue
      |> map (group: group.name);
    resolvedExtraGroups =
      posixGroups
      |> lib.filterAttrs (name: group: name != user.name && userInGroup group)
      |> builtins.attrNames
      |> (groups: groups ++ directResolvedGroups ++ lib.optional user.system.isAdmin "wheel")
      |> lib.unique;
  in {
    users.users.${user.name} = {
      isNormalUser = true;
      uid = lib.mkIf (user.system.uid != null) user.system.uid;
      description = user.identity.displayName or user.name;
      extraGroups = builtins.trace directResolvedGroups resolvedExtraGroups;
      openssh.authorizedKeys.keys = map (key: key.key) (user.identity.sshKeys or []);
      password = "arst";
    };
  };
}

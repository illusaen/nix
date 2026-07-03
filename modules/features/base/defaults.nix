{lib, ...}: {
  debug = true;
  flake.modules.generic.defaults = {host, ...}: {
    nixpkgs.hostPlatform = host.system;
    networking.hostName = host.name;
  };

  flake.modules.nixos.defaults = {
    fleet,
    host,
    user,
    ...
  }: let
    isPosixGroup = _name: group: group.isPosix or false;
    resolvedGroups =
      (user.resolvedGroups or [])
      |> builtins.filter (name: (fleet.groups.${name} or null) != null)
      |> map (name: fleet.groups.${name});
    resolvedExtraGroups =
      resolvedGroups
      |> builtins.filter isPosixGroupValue
      |> map (group: group.name)
      |> (groups: groups ++ lib.optional user.system.isAdmin "wheel")
      |> lib.unique;
    isPosixGroupValue = group: isPosixGroup (group.name or "") group;
  in {
    users.users.${user.name} = {
      isNormalUser = true;
      uid = lib.mkIf (user.system.uid != null) user.system.uid;
      description = user.identity.displayName or user.name;
      extraGroups = resolvedExtraGroups;
      openssh.authorizedKeys.keys = map (key: key.key) (user.identity.sshKeys or []);
      password = "arst";
    };

    hardware = lib.mkIf (host.system != "x86_64-linux") {
      cpu.amd.updateMicrocode = lib.mkForce false;
      cpu.intel.updateMicrocode = lib.mkForce false;
    };
  };
}

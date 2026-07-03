{lib, ...}: {
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
    resolvedExtraGroups =
      (user.resolvedGroups or [])
      |> builtins.filter (name: fleet.groups.${name}.isPosix or false)
      |> (groups: groups ++ lib.optional user.system.isAdmin "wheel")
      |> lib.unique;
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

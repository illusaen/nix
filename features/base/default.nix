{sources}: {
  imports = [
    ./shell-utils
    ./networking.nix
    ./nix-settings.nix
    ./secrets.nix
    ./ssh.nix
    ./tailscale.nix
  ];

  modules = {
    generic = {user, ...}: {
      hjem.users.${user.name}.enable = true;
    };

    nixos = {
      fleet,
      fleetLib,
      lib,
      user,
      ...
    }: let
      posixGroups = fleetLib.userPosixGroups fleet user.name;
      extraGroups = lib.unique (posixGroups ++ lib.optional (user.system.isAdmin or false) "wheel");
    in {
      imports = [
        (import "${sources.hjem.outPath}/modules/nixos").default
      ];

      system.stateVersion = "26.11";

      nixpkgs.config.allowUnfree = true;

      users.users.${user.name} = {
        isNormalUser = true;
        uid = lib.mkIf ((user.system.uid or null) != null) user.system.uid;
        description = user.identity.displayName or user.name;
        inherit extraGroups;
        openssh.authorizedKeys.keys = map (key: key.key) (user.identity.sshKeys or []);
        password = "arst";
      };
    };

    darwin = {host, ...}: {
      imports = [
        (import "${sources.hjem.outPath}/modules/nix-darwin").default
      ];

      system.stateVersion = 6;

      homebrew = {
        enable = true;
        user = host.owner;
      };
    };
  };
}

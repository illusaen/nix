{
  imports = [
    "shell-utils"
    ./secrets.nix
    ./ssh.nix
    ./tailscale.nix
    ./networking.nix
    ./nix-settings.nix
  ];

  modules.nixos = {
    fleet,
    fleetLib,
    host,
    lib,
    sources,
    user,
    ...
  }: let
    userName = user.name or host.owner;
    posixGroups = fleetLib.userPosixGroups fleet userName;
    extraGroups = lib.unique (posixGroups ++ lib.optional (user.system.isAdmin or false) "wheel");
  in {
    imports = [
      (import "${sources.hjem.outPath}/modules/nixos").default
    ];

    system.stateVersion = "26.11";

    hjem.users.${userName}.enable = true;

    nixpkgs.config.allowUnfree = true;

    users.users.${userName} = {
      isNormalUser = true;
      uid = lib.mkIf ((user.system.uid or null) != null) user.system.uid;
      description = user.identity.displayName or userName;
      inherit extraGroups;
      openssh.authorizedKeys.keys = map (key: key.key) (user.identity.sshKeys or []);
      password = "arst";
    };
  };

  modules.darwin = {
    host,
    sources,
    ...
  }: {
    imports = [
      (import "${sources.hjem.outPath}/modules/nix-darwin").default
    ];

    system.stateVersion = 6;

    homebrew = {
      enable = true;
      user = host.owner;
    };
  };
}

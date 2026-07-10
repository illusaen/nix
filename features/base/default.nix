_: {
  imports = ["nix-settings" "secrets" "shell-utils" "ssh" "tailscale"];

  modules.nixos = {
    fleet,
    fleetLib,
    host,
    lib,
    user,
    ...
  }: let
    userName = user.name or host.owner;
    posixGroups = fleetLib.userPosixGroups fleet userName;
    extraGroups = lib.unique (posixGroups ++ lib.optional (user.system.isAdmin or false) "wheel");
    staticInterfaces = host.networkInterfaces or {};
    hasStaticInterfaces = staticInterfaces != {};
    mkNetwork = name: interface:
      lib.nameValuePair "10-${name}" {
        matchConfig.Name = name;
        address = lib.optional (interface ? ipv4) interface.ipv4 ++ lib.optional (interface ? ipv6) interface.ipv6;
        routes = [
          {Gateway = "192.168.1.1";}
          {Gateway = "fe80::1";}
        ];
        linkConfig.RequiredForOnline = "routable";
      };
  in {
    system.stateVersion = "26.11";

    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "1password"
        "1password-cli"
        "1password-gui"
        "1password-gui-beta"
        "bambu-studio"
        "nvidia-kernel-modules"
        "nvidia-settings"
        "nvidia-x11"
        "steam"
        "steam-original"
        "steam-run"
        "steam-unwrapped"
      ];

    networking = {
      hostName = host.name or null;
      inherit (fleet) domain;
      inherit (host) hostId;
      networkmanager.enable = !hasStaticInterfaces;
      useDHCP = !hasStaticInterfaces;
      useNetworkd = hasStaticInterfaces;
    };

    systemd.network = lib.mkIf hasStaticInterfaces {
      enable = true;
      wait-online.anyInterface = true;
      networks = lib.mapAttrs' mkNetwork staticInterfaces;
    };

    users.users.${userName} = {
      isNormalUser = true;
      uid = lib.mkIf ((user.system.uid or null) != null) user.system.uid;
      description = user.identity.displayName or userName;
      inherit extraGroups;
      openssh.authorizedKeys.keys = map (key: key.key) (user.identity.sshKeys or []);
      password = "arst";
    };

    security.sudo-rs.enable = true;

    hardware = lib.mkIf (host.system != "x86_64-linux") {
      cpu.amd.updateMicrocode = lib.mkForce false;
      cpu.intel.updateMicrocode = lib.mkForce false;
    };
  };

  modules.darwin = {host, ...}: {
    system.stateVersion = 6;
    networking.computerName = host.name or host.targetHost;
  };
}
